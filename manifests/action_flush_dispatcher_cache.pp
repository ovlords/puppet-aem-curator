class aem_curator::action_flush_dispatcher_cache (
  $docroot_dir,
  $user  = 'apache',
  $group = 'apache',
) {
  file { [
      "${docroot_dir}/apps",
      "${docroot_dir}/bin",
      "${docroot_dir}/conf",
      "${docroot_dir}/content",
      "${docroot_dir}/etc",
      "${docroot_dir}/etc.clientlibs",
      "${docroot_dir}/home",
      "${docroot_dir}/libs",
      "${docroot_dir}/system",
      "${docroot_dir}/tmp",
      "${docroot_dir}/var"
    ]:
  ensure  => directory,
  purge   => true,
  force   => true,
  recurse => true,
  owner   => $user,
  group   => $group,
  }
}
