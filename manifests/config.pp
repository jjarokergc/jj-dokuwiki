# Dokuwiki Configuration
# Create local configuration file using data in hiera
# and concat file fragments approach
class dokuwiki::config {
  # VARIABLES
  $provisioning = lookup('dokuwiki::provisioning')
  $configuration= lookup('dokuwiki::local')
  $code_source  = lookup('dokuwiki::source')
  $mime_types   = lookup('dokuwiki::mime')                    # conf/mime.local.conf file

  $server_name = $configuration['server']['fqdn']             # Example 'example.com'
  $vhost_dir = "${provisioning['wwwroot']}/${server_name}"    # Virtual host directory, example '/var/www/example.com'
  $www_root = "${vhost_dir}/${code_source['repo']['subdir']}" # Location for dockuwiki, example '/var/www/example.com/htdocs'
  $user = $provisioning['user']                               # User and Group Ownership
  $group = $provisioning['group']

  # Local Configuration File Setup
  concat { 'dokuwiki-local.php':
    ensure  => present,
    path    => "${www_root}/conf/local.php",
    mode    => '0644',
    owner   => $user,
    group   => $group,
    replace => $configuration['overwrite']['local_conf'],
  }
  concat::fragment { 'dokuwiki-local.php Header':
    target  => 'dokuwiki-local.php',
    content => epp('dokuwiki/local.php.header.epp'),
    order   => '01',
  }

  # Add configuration values defined in dokuwiki::local[conf] 
  $conf_template = @(END)
$conf['<%= $n %>'] = '<%= $v %>';
  END
  $local_config = $configuration['conf']    # Key=>Value pairs for local configuration
  $local_config.each | String $n, String $v | {
    concat::fragment { "conf[${n}]":
      target  => 'dokuwiki-local.php',
      content => inline_epp($conf_template),
      order   => '10',
    }
  }

  # Mime Configuration File Setup
  # Local Configuration File Setup
  concat { 'mime.local.conf':
    ensure  => present,
    path    => "${www_root}/conf/mime.local.conf",
    mode    => '0644',
    owner   => $user,
    group   => $group,
    replace => true,
  }
  concat::fragment { 'mime.local.conf Header':
    target  => 'mime.local.conf',
    content => "# File Managed by Puppet\n\n",
    order   => '01',
  }
  # Add configuration values defined in dokuwiki::local[conf] 
  $mime_template = @(END)
    <%= $n %>  <%= $v %>
  END
  $mime_types.each | String $n, String $v | { # Key=>Value pairs for local configuration
    concat::fragment { "mime type - ${n}":
      target  => 'mime.local.conf',
      content => inline_epp($mime_template),
      order   => '10',
    }
  }
}
