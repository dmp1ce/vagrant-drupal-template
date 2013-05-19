file { '/etc/motd.tail':
  content => "===================================================================
This VM hosts the default drupal-vagrant.local development website.
Designed specifically for quickly developing Drupal based products.

For help with this VM please contact dave@upgradeya.com.
===================================================================
"
}

# make sure the packages are up to date before beginning
exec { "apt-get update":
  command => "/usr/bin/apt-get update",
}

# because puppet command are not run sequentially, ensure that packages are
# up to date before installing before installing packages, services, files, etc.
Exec["apt-get update"] -> Package <| |>

# Basic Puppet Apache manifest
class apache {
  package { "apache2":
    ensure => latest,
  }

  service { "apache2":
    ensure => running,
    require => [ Package["apache2"], File['/vagrant/log'] ],
  }

  file { "/etc/apache2/sites-available/drupal":
    owner   => "root",
    group   => "root",
    mode    => 644,
    replace => true,
    ensure  => present,
    source  => "/vagrant/files/drupal",
    require => Package["apache2"],
  }

  # ensures that mod_rewrite is loaded and modifies the default configuration file
  file { "/etc/apache2/mods-enabled/rewrite.load":
    ensure => link,
    target => "/etc/apache2/mods-available/rewrite.load",
    require => Package['apache2'],
  }

  # Turn on Drupal site
  file { "/etc/apache2/sites-enabled/drupal":
    ensure => link,
    target => "/etc/apache2/sites-available/drupal",
    require => [ Package['apache2'], File['/etc/apache2/sites-available/drupal'] ],
    notify  => Service["apache2"]
  }

  # Make sure the log directory exists
  file { "/vagrant/log":
    ensure => "directory",
    owner => "vagrant",
    group => "vagrant",
    mode   => 644,
  }
}

# Setup MySQL
class mysql {
  require apache

  package { "mysql-server":
    ensure => latest,
  }

  package { "libapache2-mod-auth-mysql":
    ensure => latest,
  }

  package { "php5-mysql":
    ensure => latest,
  }

  service { "mysql":
    ensure => running,
    require => Package["mysql-server"],
  }

}

# Setup PHP
class php {
  require apache

  package { "libapache2-mod-php5":
    ensure => latest,
  }
  package { "php5":
    ensure => latest,
  }

  # ensures that mod_php5 is loaded and modifies the default configuration file
  file { "/etc/apache2/mods-enabled/php5.load":
    ensure => link,
    target => "/etc/apache2/mods-available/php5.load",
    require => [ Package['apache2'], Package['libapache2-mod-php5'] ],
  }

  package { "php5-cli":
    ensure => latest,
  }

  package { "php5-gd":
    ensure => latest,
  }
}

class mysql_setup {
  require mysql

  $dbname = 'website'
  $dbuser = 'website'
  $dbpass = 'password'

  exec { 'create-db':
    unless => "/usr/bin/mysql -u${$dbuser} -p${dbpass} ${dbname}",
    command => "/usr/bin/mysql -e \"create database ${dbname}; grant all on ${dbname}.* to ${dbuser}@localhost identified by '${dbpass}';\"",
    require => Service["mysql"],
  }
}

class git {
  package { "git":
    ensure => latest,
  }
}

class drush::params {
  $branch_name = "7.x-5.x"
}

class drush {
  require git
  require drush::params

  exec { 'fetch-drush':
    cwd     => '/usr/local/share',
    command => "/usr/bin/git clone --branch $drush::params::branch_name http://git.drupal.org/project/drush.git",
    require => Package['php5-cli', 'git'], 
    creates => '/usr/local/share/drush',
  }

  exec { 'update-drush':
    cwd     => '/usr/local/share/drush',
    command => "/usr/bin/git pull",
    require => Package['php5-cli', 'git'], 
    onlyif => '/usr/bin/test -e /usr/local/share/drush',
  }

  file { '/usr/local/bin/drush':
    ensure  => link,
    purge   => false,
    target => "/usr/local/share/drush/drush",
    require => Exec['fetch-drush'],
  }

  # Creates the Console_Table lib for drush
  exec { "initialize-drush":
    command => "/usr/local/bin/drush",
    creates => "/usr/local/share/drush/lib/Console_Table-1.1.3",
    require => File['/usr/local/bin/drush'],
  }
}

include mysql
include apache
include php
include mysql_setup
include git
include drush::params
include drush
