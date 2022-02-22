# Puppet Module for Dokuwiki

## Repositories

The development repository is located at: <https://gitlab.jaroker.org>

A mirror repository is pushed to: <https://github.com/jjarokergc/puppet-webtrees>

## Architecture

This dokuwiki application is hosted with NGINX and is designed to be behind a reverse proxy.  The reverse proxy provides SSL offloading and a ModSecurity firewall.

The puppet module uses hiera for data lookup, which specifies source location (and version) for downloading, nginx configuration and php setup.

## Requirements

Puppetfile.r10k

```
mod 'puppetlabs-concat', '7.1.1'
mod 'puppetlabs-stdlib', '8.1.0'
mod 'puppetlabs-vcsrepo', '5.0.0'
mod 'puppet-nginx', '3.3.0'
mod 'puppet-php', '8.0.2'
```

## Usage Example

manifests/site.pp

```
node 'dokuwiki.datacenter'{                 # webtrees.findfollow.com
  include role::app::dokuwiki_server
}
```

site/role/app/dokuwiki_server.pp

```
#
# Install Dokuwiki website
# Configure reverse proxy with SSL
# Requires data in dockuwiki hiera
#
class role::app::dokuwiki_server {

  include profile::base::common

  # Install Dokuwiki
  include profile::dokuwiki
  # Export configuration required for NGINX reverse proxy
  # and SSL Certificate for the external domain
  include profile::nginx::reverse_proxy_export
}
```

site/profile/dokuwiki.pp

```
# Install Dokuwiki and Plugins
# Install NGINX server with PHP
# Configure users and settings
# Requires data in dockuwiki hiera
#
class profile::dokuwiki{
  # Install dokuwiki and plugins
  include ::dokuwiki
  include ::dokuwiki::plugins
  include ::dokuwiki::nginx
  include ::dokuwiki::users
  include ::dokuwiki::config
}
```

## Author

Jon Jaroker
devops@jaroker.com
