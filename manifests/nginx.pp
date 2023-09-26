# Configure NGINX server with php for Dokuwiki
# Requires nginx package
# Servers dokuwiki on socket
#
class dokuwiki::nginx {
  # VARIABLES
  $provisioning = lookup('dokuwiki::provisioning')  # OS-specific parameters
  $configuration= lookup('dokuwiki::local')         # Host-specific parameters
  $code_source  = lookup('dokuwiki::source')        # Host-specific parameters

  $server_urls = $configuration['server']['urls']           # Example ['example.com', 'www.example.com']
  $server_name = $configuration['server']['fqdn']           # Example 'example.com'
  $vhost_dir = "${provisioning['wwwroot']}/${server_name}"  # Virtual host directory, example '/var/www/example.com'
  $www_root = "${vhost_dir}/${code_source['repo']['subdir']}"   # Location for dockuwiki, example '/var/www/example.com/htdocs'
  $plugins_dir = "${www_root}/lib/plugins"                  # Location for additional plugins,'var/www/example.com/htdocs/lib/plugins'
  $socket = $provisioning['php-fpm']['sock']                # PHP-fpm Config

  # NGINX WEB SERVER
  class { 'nginx':
    server_tokens         => 'off', # Security precaution: don't show nginx version number
  }

  # Create virtual server
  nginx::resource::server { $server_name:
    server_name          => $server_urls, # List of urls for server
    use_default_location => false,
    www_root             => $www_root,
    index_files          => [],
    client_max_body_size => $configuration['server']['client_max_body_size'],
    require              => Vcsrepo[$www_root],
  }
  nginx::resource::location { '/':
    server      => $server_name,
    index_files => ['doku.php'],
    try_files   => ['$uri', '$uri/', '@dokuwiki'],
  }
  nginx::resource::location { '~ ^/lib.*\.(js|css|gif|png|ico|jpg|jpeg)$':
    server      => $server_name,
    expires     => '30d',
    index_files => [],
  }
  nginx::resource::location { '~ /(install.php|conf|bin|inc)/':
    server        => $server_name,
    index_files   => [],
    location_deny => ['all'],
  }
  nginx::resource::location { '~ ^/data/':
    server      => $server_name,
    index_files => [],
    internal    => true,
  }
  nginx::resource::location { '@dokuwiki':
    server        => $server_name,
    index_files   => [],
    rewrite_rules => [
      '^/_media/(.*)  /lib/exe/fetch.php?media=$1 last',
      '^/_detail/(.*) /lib/exe/detail.php?media=$1 last',
      '^/_export/([^/]+)/(.*) /doku.php?do=export_$1&id=$2 last',
      '^/(.*) /doku.php?id=$1&$args last',
    ],
  }
  nginx::resource::location { '~ \.php':
    server        => $server_name,
    index_files   => [],
    try_files     => ['$uri', '$uri/', '/doku.php'],
    # include       => ['fastcgi_params'], # Duplicate
    fastcgi_param => { 'SCRIPT_FILENAME' => '$document_root$fastcgi_script_name' },
    fastcgi       => "unix:${socket}",
} }
