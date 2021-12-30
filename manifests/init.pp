
#  Dokuwiki and plugins installation
#
class dokuwiki {

  # VARIABLES
  $provisioning = lookup('dokuwiki::provisioning')  # OS-specific parameters
  $nx           = lookup('nginx::reverse_proxy')    # Reverse proxy
  $configuration= lookup('dokuwiki::local')         # Host-specific parameters
  $code_source  = lookup('dokuwiki::source')        # Host-specific parameters

  $server_name = $nx[server][fqdn]                     # Example 'example.com'
  $vhost_dir = "${provisioning[wwwroot]}/${server_name}"  # Virtual host directory, example '/var/www/example.com'
  $www_root = "${vhost_dir}/${code_source[repo][subdir]}" # Location for dockuwiki, example '/var/www/example.com/htdocs'
  $socket = $provisioning['php-fpm']['sock']        # PHP-fpm Config

  # Install Required Packages for Dokuwiki
  package {$code_source[packages]: ensure => present }

  # Install PHP and PHP-XML for NGINX
  file {$socket:
    owner => $provisioning[user],
    group => $provisioning[group],
  }
  class{'::php':
    ensure     => present,
    fpm        => true,
    dev        => false,
    composer   => false,
    pear       => true,
    phpunit    => false,
    fpm_pools  => {
            'www' => {
              'catch_workers_output'      => 'no',
              'listen'                    => $socket,
              'listen_owner'              => $provisioning[user],
              'listen_group'              => $provisioning[group],
              'listen_backlog'            => 511,
              'pm'                        => 'dynamic',
              'pm_max_children'           => 5,
              'pm_max_requests'           => 0,
              'pm_max_spare_servers'      => 3,
              'pm_min_spare_servers'      => 1,
              'pm_start_servers'          => 2,
              'request_terminate_timeout' => 0,
                },
              },
    extensions => {
            'xml' => {},
              },
  }

  # Virtual Host Directory
  file{ [
          $provisioning[wwwroot],
          $vhost_dir
        ]:
    ensure => directory,
    owner  => $provisioning[user],
    group  => $provisioning[group],
    mode   => '0755',
  }
  # Dokuwiki Installation
  vcsrepo { $www_root :
    ensure            => 'present',
    provider          => 'git',
    trust_server_cert => true,
    source            => $code_source[repo][url],
    revision          => $code_source[repo][revision],
    depth             => 1,
    user              => $provisioning[user],
    require           => File[$vhost_dir],
  }
  # Robots.txt file
  file{"${www_root}/robots.txt":
    ensure  => present,
    source  => 'puppet:///modules/dokuwiki/robots.txt',
    mode    => '0644',
    require => Vcsrepo[$www_root],
  }
  # Disable installation script
  file {"${www_root}/install.php":
    ensure  => absent,
    require => Vcsrepo[$www_root],
  }
}
