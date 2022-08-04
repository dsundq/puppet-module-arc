# @summary Manages tcl-devel package, libtcl symlink and /etc/rndrelease.
#
# This module requires that you have OpenAFS installed. It is intended to be used in cooperation with
# puppet-module-afs. It is needed for modulecmd to work properly on all platforms.
#
# @param manage_rndrelease
#   Boolean to trigger management of /etc/rndrelease file.
#
# @param create_rndrelease
#   Boolean to trigger creation of /etc/rndrelease file.
#
# @param create_symlink
#   Boolean to trigger creation of libtcl symlink.
#
# @param install_package
#   Boolean to trigger installation of packages.
#
# @param packages
#   Array with package names to be installed.
#
# @param rndrelease_version
#   String containing the content for /etc/rndrelease.
#   If set to undef /etc/rndrelease will be deleted.
#
# @param symlink_target
#   Absolute path to the target of the libtcl symlink.
#
# @param manage_arc_console_icon
#   Boolean to trigger if arc_console.desktop should be managed.
#
# @param arc_console_icon
#   Boolean to trigger creation (true) or deletion (false) of arc_console.desktop for the the arc_console.
#
class arc (
  Boolean $manage_rndrelease = true,
  Boolean $create_rndrelease = true,
  Boolean $create_symlink = true,
  Boolean $install_package = true,
  Optional[Array[String[1]]] $packages = undef,
  Optional[String[1]] $rndrelease_version = undef,
  Optional[Stdlib::Absolutepath] $symlink_target = undef,
  Boolean $manage_arc_console_icon = false,
  Boolean $arc_console_icon = false,
) {
  # <define os default values>
  # Set $os_defaults_missing to true for unspecified osfamilies

  case "${facts['os']['name']}-${facts['os']['release']['full']}" {
    /^(RedHat|CentOS)-5/: {
      $os_defaults_missing        = false
    }
    /^(RedHat|CentOS)-6/: {
      $os_defaults_missing        = false
    }
    /^(RedHat|CentOS)-7/: {
      $os_defaults_missing        = false
    }
    /^(RedHat|CentOS)-8/: {
      $os_defaults_missing        = false
    }
    /^(SLED-10|SLES-10)/: {
      $os_defaults_missing        = false
    }
    /^(SLED-11|SLES-11)/: {
      $os_defaults_missing        = false
    }
    /^(SLED-12|SLES-12|SLED-15|SLES-15)/: {
      $os_defaults_missing        = false
    }
    /^(Ubuntu-12|Ubuntu-14|Ubuntu-16|Ubuntu-18|Ubuntu-20)/: {
      $os_defaults_missing        = false
    }
    default: {
      $os_defaults_missing = true
    }
  }
  # </define os default values>

  # <USE_DEFAULTS vs OS defaults>
  # Check if 'USE_DEFAULTS' is used anywhere without having OS default value
  if (
    ($packages           == undef and $install_package   != true) or
    ($rndrelease_version == undef and $create_rndrelease != true) or
    ($symlink_target     == undef and $create_symlink    != true)
  ) and $os_defaults_missing == true {
    fail("Sorry, I don't know default values for ${facts['os']['name']}-${facts['os']['release']['full']} yet :( Please provide specific values to the arc module.") #lint:ignore:140chars
  }
  # </USE_DEFAULTS vs OS defaults>

  # <Do Stuff>
  if ($create_rndrelease == false or $rndrelease_version == undef) {
    $rndrelease_ensure = 'absent'
  } else {
    $rndrelease_ensure = 'present'
  }

  if $manage_rndrelease == true {
    file { 'arc_rndrelease':
      ensure  => $rndrelease_ensure,
      path    => '/etc/rndrelease',
      mode    => '0644',
      content => "${rndrelease_version}\n",
    }
  }

  if $facts['os']['name'] == 'Ubuntu' {
    # In 20.xx and later /bin is a symlink to usr/bin
    if $facts['os']['release']['full'] =~ /^(10|12|14|16|18)/ {
      file { 'awk_symlink':
        ensure => link,
        path   => '/bin/awk',
        target => '/usr/bin/awk',
      }
    }

    exec { 'locale-gen':
      command => '/usr/sbin/locale-gen en_US',
      unless  => '/usr/bin/locale -a |grep -q ^en_US.iso88591$',
      path    => '/bin:/usr/bin:/sbin:/usr/sbin',
    }
  }

  if ($create_symlink == true and $symlink_target != undef) {
    file { 'arc_symlink':
      ensure => link,
      path   => '/usr/lib/libtcl.so.0',
      target => $symlink_target,
    }
  }

  if $install_package == true and $packages != undef {
    package { $packages:
      ensure => present,
    }
  }

  if $manage_arc_console_icon == true {
    if $arc_console_icon == true {
      file { 'arc_console.desktop':
        ensure => file,
        path   => '/usr/share/applications/arc_console.desktop',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/arc/arc_console.desktop', # lint:ignore:fileserver
      }
    } else {
      file { 'arc_console.desktop':
        ensure => absent,
        path   => '/usr/share/applications/arc_console.desktop',
      }
    }
  }
  # </Stuff done>
}
