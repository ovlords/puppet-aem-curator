File {
  backup => false,
}

class aem_curator::action_export_backups (
  $tmp_dir,
  $descriptor_file  = $::descriptor_file,
  $component        = $::component,
  $package_version  = $::package_version,
  $stack_prefix     = $::stack_prefix,
  $data_bucket_name = $::data_bucket_name,
) {

  # configure logrotate for export-backups.log file see daily-export-backups cron job in author-primary and publish manifest
  file { '/var/log/export-backups':
    ensure => 'directory',
  }  -> logrotate::rule { 'export-backups':
    path         => '/var/log/export-backups.log',
    rotate       => 5,
    size         => '200M',
    dateext      => true,
    rotate_every => 'day',
    olddir       => '/var/log/export-backups',
  }

  # load descriptor file
  $descriptor_hash = loadjson("${tmp_dir}/${descriptor_file}")
  notify { "The descriptor_hash is: ${descriptor_hash}": }

  # extract component hash
  $component_hash = $descriptor_hash[$component]
  notify { "The component_hash is: ${component_hash}": }

  if $component_hash {

    file { $tmp_dir:
      ensure => directory,
      mode   => '0775',
    }

    $packages = $component_hash['packages']
    notify { "The packages is: ${packages}": }

    if $packages {

      class { 'aem_curator::export_backup_packages':
        tmp_dir         => $tmp_dir,
        backup_path     => $::backup_path,
        packages        => $packages,
        package_version => $package_version,
      }

    } else {
      notify { "no 'packages' defined for component: ${component} in descriptor file: ${descriptor_file}. nothing to backup": }
    }


  } else {
    notify { "component: ${component} not found in descriptor file: ${descriptor_file}. nothing to backup": }
  }

}

class aem_curator::export_backup_packages (
  $tmp_dir,
  $backup_path,
  $packages,
  $package_version,
) {

  $packages.each | Integer $index, Hash $package| {

    if !defined(File["${tmp_dir}/${package[group]}"]) {

      exec { "Create ${tmp_dir}/${package[group]}":
        creates => "${tmp_dir}/${package[group]}",
        command => "mkdir -p ${tmp_dir}/${package[group]}",
        cwd     => $tmp_dir,
        path    => ['/usr/bin', '/usr/sbin'],
      } -> file { "${tmp_dir}/${package['group']}":
        ensure => directory,
        mode   => '0775',
      }

    }

    aem_package { "Create and download backup file for package: ${package[name]}":
      ensure  => archived,
      name    => $package[name],
      version => $package_version,
      group   => $package[group],
      path    => "${tmp_dir}/${package['group']}",
      filter  => $package[filter],
      require => File["${tmp_dir}/${package['group']}"],
    } -> exec { "aws s3 cp ${tmp_dir}/${package[group]}/${package[name]}-${package_version}.zip s3://${data_bucket_name}/backup/${stack_prefix}/${package[group]}/${backup_path}/${package[name]}-${package_version}.zip":
      cwd  => $tmp_dir,
      path => ['/bin'],
    } -> file { "${tmp_dir}/${package[group]}/${package[name]}-${package_version}.zip":
      ensure => absent,
    }

  }

}
