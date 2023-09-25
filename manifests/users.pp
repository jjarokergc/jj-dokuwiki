# Dokuwiki - Load Users
#
class dokuwiki::users {
  # VARIABLES
  $provisioning = lookup('dokuwiki::provisioning')  # OS-specific parameters
  $configuration= lookup('dokuwiki::local')         # Host-specific parameters
  $code_source  = lookup('dokuwiki::source')        # Host-specific parameters

  $server_name = $configuration['server']['fqdn']             # Example 'example.com'
  $vhost_dir = "${provisioning['wwwroot']}/${server_name}"    # Virtual host directory, example '/var/www/example.com'
  $www_root = "${vhost_dir}/${code_source['repo']['subdir']}" # Location for dockuwiki, example '/var/www/example.com/htdocs'

  # User and Group Ownership
  $user = $provisioning['user']
  $group = $provisioning['group']

  # User Accounts - Initial Account Creation
  concat { 'dokuwiki-users.auth.php':
    ensure  => present,
    path    => "${www_root}/conf/users.auth.php",
    owner   => $user,
    group   => $group,
    replace => $configuration['overwrite']['user_accounts'],
  }
  concat::fragment { 'dokuwiki_user_header':
    target  => 'dokuwiki-users.auth.php',
    content => template('dokuwiki/user_header.erb'),
    order   => '01',
  }
  # Create default users
  $users = lookup('dokuwiki::users')
  $users.each | String $n, Hash $h | { # 'n' name; 'h' hash
    concat::fragment { "dokuwiki_user_${n}":
      target  => 'dokuwiki-users.auth.php',
      content => epp('dokuwiki/user.epp',
        {
          'login'        => $n,
          'passwordhash' => $h[passwordhash],
          'real_name'    => $h[real_name],
          'email'        => $h[email],
          'groups'       => $h[groups],
        }
      ),
      order   => '10',
    }
  }
}
