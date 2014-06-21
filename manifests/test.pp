require boxen::environment
require homebrew
require gcc

Exec {
  group       => 'developers',
  logoutput   => on_failure,
  user        => $boxen_user,

  path => [
    "${boxen::config::home}/rbenv/shims",
    "${boxen::config::home}/rbenv/bin",
    "${boxen::config::home}/rbenv/plugins/ruby-build/bin",
    "${boxen::config::home}/homebrew/bin",
    '/usr/bin',
    '/bin',
    '/usr/sbin',
    '/sbin'
  ],

  environment => [
    "HOMEBREW_CACHE=${homebrew::config::cachedir}",
    "HOME=/Users/${::boxen_user}"
  ]
}

File {
  group => 'developers',
  owner => $boxen_user
}

Package {
  provider => homebrew,
  require  => Class['homebrew']
}

Repository {
  provider => git,
  extra    => [
    '--recurse-submodules'
  ],
  require  => File["${boxen::config::bindir}/boxen-git-credential"],
  config   => {
    'credential.helper' => "${boxen::config::bindir}/boxen-git-credential"
  }
}

Service {
  provider => ghlaunchd
}

Homebrew::Formula <| |> -> Package <| |>

node default {
  # core modules, needed for most things
  #include dnsmasq
  include git
  include hub
  #include nginx

  # fail if FDE is not enabled
  #if $::root_encrypted == 'no' {
  #  fail('Please enable full disk encryption and try again')
  #}

  # node versions
  include nodejs::v0_10

  # default ruby versions
  ruby::version { '2.1.2': }

  # common, useful packages
  package {
    [
      'ack',
      'findutils',
      'gnu-tar'
    ]:
  }

  file { "${boxen::config::srcdir}/our-boxen":
    ensure => link,
    target => $boxen::config::repodir
  }

  include firefox
  include phpstorm

  package { 'php53'
    ensure => present,
    install_options => [
      '--with-apache'
    ]
  }

  package { 'php53-memcached'
    ensure => present,
    require => Package["php53"]
  }

  package { 'php53-xdebug'
    ensure => present,
    require => Package['php53']
  }

  package { "php53-oauth"
    ensure => present,
    require => Package['php53']
  }

  package { "php53-igbinary"
    ensure => present,
    require => Package['php53']
  }

  package { "php53-redis"
    ensure => present,
    install_options => [
      '--with-igbinary'
    ]
    require => Package['php53', 'php53-igbinary']
  }

  package { "mcrypt"
    ensure => present
  }

  package { "php53-mcrpyt"
    ensure => present,
    require => Package['php53', 'mcrypt']
  }

  class composer {
    homebrew::tap {}
  }
}
