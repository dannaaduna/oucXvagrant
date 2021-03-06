$vagrant_dir = '/vagrant'
$conf_dir = '/home/vagrant/conf'

# SELinux
file { '/etc/selinux/config': source => "$conf_dir/selinux", }
service { 'iptables': ensure => 'stopped', hasstatus => true, }

# Erlang
package {'erlang': ensure => installed, }

# Workaround to get Erlang R15B for FC16

# yumrepo { 'erlang-solutions':
#   name => 'erlang-solutions',
#   baseurl => 'http://binaries.erlang-solutions.com/rpm/fedora/$releasever/$basearch',
#   gpgcheck => 1,
#   gpgkey => 'http://binaries.erlang-solutions.com/debian/erlang_solutions.asc',
#   enabled => 1,
# }

# package {'esl-erlang':
# 	ensure => installed,
#   require => [Exec['remove erlang-r14b'], Yumrepo['erlang-solutions']],
# }

# exec { 'remove erlang-r14b':
#   path => ['/bin', '/usr/bin'],
#   command => 'rpm -qa | grep "^erlang" | xargs rpm -e --nodeps',
#   onlyif => 'rpm -q erlang',
# }

# exec { 'kerl-r15b02':
#   path => ["/usr/bin", "/bin"],
#   command => "/home/vagrant/bin/erlr15b02install",
#   user => "vagrant",
#   creates => '/home/vagrant/.kerl/installs/r15b02',
#   environment => "HOME=/home/vagrant",
#   timeout => 0,
# }

# sipXecs

yumrepo { 'sipXecs-testing':
  name => 'sipXecs-testing',
  baseurl => 'http://download.sipfoundry.org/pub/sipXecs/snapshot/Fedora_$releasever/$basearch',
  gpgcheck => 0,
}

$sipx_build_deps = ['make', 'automake', 'libtool', 'git', 'bind', 'bind-utils',
'boost', 'boost-devel', 'cfengine', 'chkconfig', 'cppunit-devel', 'dejavu-serif-fonts', 'dhcp',
'fontconfig', 'httpd', 'mod_ssl', 'mongodb', 'mongodb-server',
'net-snmp', 'net-snmp-libs', 'net-snmp-sysvinit', 'net-snmp-utils',
'ntp', 'openssl', 'openssl-devel', 'patch', 'pcre', 'pcre-devel', 'postgresql-odbc', 'postgresql-server',
'rpm', 'rpm-libs', 'ruby', 'ruby-dbi', 'rubygem-daemons', 'rubygems', 'ruby-libs', 'ruby-postgres',
'sec', 'sendmail', 'sendmail-cf', 'shadow-utils', 'stunnel', 'tftp', 'tftp-server', 'unixODBC',
'unixODBC-devel', 'vsftpd', 'which', 'xerces-c', 'xerces-c-devel']

package { $sipx_build_deps: ensure => "installed", require => Yumrepo['sipXecs-testing'] }

# freeswitch

package { 'freeswitch': ensure => "installed", require => Yumrepo['sipXecs-testing'] }

# mongodb

file { '/etc/mongod.conf':
  source => "$conf_dir/mongod.conf",
  require => Package['mongodb-server'],
}

# OpenACD

# Apache httpd

service { 'httpd':
  ensure => 'running',
  require => [Package['httpd'], File['/etc/httpd/conf.d/ouc-vhost.conf']],
}

file { '/etc/httpd/conf.d':
  ensure => 'directory',
  require => Package['httpd'],
}

file { '/etc/httpd/conf.d/ouc-vhost.conf':
  source => "$conf_dir/ouc-vhost.conf",
  require => File['/etc/httpd/conf.d'],
}

# oucXopenACDWeb

package { 'java-1.7.0-openjdk-devel': ensure => 'installed', }

# play

exec { 'get_play_framework':
  command => '/usr/bin/wget http://download.playframework.org/releases/play-2.0.3.zip -O /tmp/play-2.0.3.zip && /usr/bin/unzip -d /opt /tmp/play-2.0.3.zip',
  creates => '/opt/play-2.0.3',
  timeout => 0,
  require => Package['wget', 'unzip']
}

file { '/opt/play-2.0.3':
  ensure => 'directory',
  # owner => 'vagrant',
  # group => 'vagrant',
  # recurse => 'true',
  require => Exec['get_play_framework'],
}

# Workaround for File['/opt/play-2.0.3'] owner/group due to performance issues with recursive file management in Puppet 2.6
exec { 'chown /opt/play-2.0.3':
  command => "/bin/chown -R vagrant:vagrant /opt/play-2.0.3",
  require => File['/opt/play-2.0.3'],
}

# Utils

package {'wget': ensure => installed, }
package {'unzip': ensure => installed, }
package {'mongo': ensure => installed, provider => 'gem', }
package {'bson_ext': ensure => installed, provider => 'gem', }

package {'ack': ensure => installed, }
package {'vim-minimal': ensure => latest, }
package {'vim-enhanced': ensure => installed, require => Package['vim-minimal'], }

# Home

file { '/home/vagrant/.bashrc':
  owner => 'vagrant',
  group => 'vagrant',
  source => '/home/vagrant/conf/.bashrc',
}

file { '/home/vagrant/workspace':
  ensure => 'directory',
  owner => 'vagrant',
  group => 'vagrant',
}

file { '/home/vagrant/workspace/openacd':
  ensure => 'link',
  target => '/home/vagrant/workspace/sipxecs/OpenACD',
  owner => 'vagrant',
  group => 'vagrant',
}