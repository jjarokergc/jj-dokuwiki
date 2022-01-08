# Install Dokuwiki Plugins
#
class dokuwiki::plugins{

  # VARIABLES
  $provisioning = lookup('dokuwiki::provisioning')  # OS-specific parameters
  $nx           = lookup('nginx::reverse_proxy')    # Reverse proxy
  $configuration= lookup('dokuwiki::local')         # Host-specific parameters
  $code_source  = lookup('dokuwiki::source')        # Host-specific parameters

  $server_name = $nx['server']['name']                     # Example 'example.com'
  $vhost_dir = "${provisioning['wwwroot']}/${server_name}"  # Virtual host directory, example '/var/www/example.com'
  $www_root = "${vhost_dir}/${code_source['repo']['subdir']}" # Location for dockuwiki, example '/var/www/example.com/htdocs'

  # Plugin Installation
  $plugins = $code_source[plugins]          # Hash of plugins to install
  $plugins_dir = "${www_root}/lib/plugins"  # Location for additional plugins, example 'var/www/example.com/htdocs/lib/plugins'

  $plugins.each | String $n, Hash $plugin | {    # "n" - name of plugin; "plugin" - hash of plugin parameters

    if $plugin[enabled] {  # Plugin is managed by puppet

      if $plugin[ensure] == 'present' { # Plugin shoud be installed
        # Install Plugin
        vcsrepo{ "${plugins_dir}/${n}":
          ensure            => present,
          provider          => 'git',
          trust_server_cert => true,
          source            => $plugin[url],
          revision          => $plugin[revision],
          depth             => 1,
          user              => $provisioning[user],
          require           => Vcsrepo[$www_root],
        } # end of Install Plugin
        # Add optional configuration parameters for plugin
        if has_key($plugin,'conf') { # Config parameters are included for plugin
          $conf_template = @(END)
$conf['plugin']['<%= $n %>']['<%= $k %>'] = '<%= $v %>';
          END
          $local_config = $plugin[conf]
          $local_config.each | String $k, String $v | { # Key 'k' => Value 'v' pairs for local configuration
            concat::fragment {"conf[plugin][${n}][${k}]":
              target  => 'dokuwiki-local.php',
              content => inline_epp($conf_template),
              order   => '20',
            } # Add key to local configuration file using file-fragment
          } # Iterate over each configuration key
        } # If plugin has configuration parameters

      } else { file {"${plugins_dir}/${n}": ensure => absent, force => true } }  # Plugin is managed by puppet and should be purged

    } # If enabled, Plugin is managed by puppet

  } # Iterate over each plugin

}
