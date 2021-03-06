# munin::plugin
#
# Parameters:
#
# - ensure: "link", "present", "absent" or "". Default is "". The
#   ensure parameter is mandatory for installing a plugin.
# - source: when ensure => present, source file
# - target: when ensure => link, link target.  If target is an
#   absolute path (starts with "/") it is used directly.  If target is
#   a relative path, $munin::node::plugin_share_dir is prepended.
# - config: array of lines for munin plugin config
# - config_label: label for munin plugin config

define munin::plugin (
    $ensure           = '',
    $target           = '',
    $source           = undef,
    $config           = undef,
    $config_label     = undef,
    $plugin_share_dir = $::munin::params::node::plugin_share_dir,
    $package_name     = $::munin::params::node::package_name,
    $service_name     = $::munin::params::node::service_name,
    $config_root      = $::munin::params::node::config_root,
    $file_group       = $::munin::params::node::file_group,
) {

    include ::munin::node

    validate_absolute_path($plugin_share_dir)
    validate_absolute_path($config_root)

    File {
        require => Package[$package_name],
        notify  => Service[$service_name],
    }

    validate_re($ensure, '^(|link|present|absent)$')
    case $ensure {
        'present', 'absent': {
            $handle_plugin = true
            $plugin_ensure = $ensure
            $plugin_target = undef
            $file_path     = "${plugin_share_dir}/${title}"
        }
        'link': {
            $handle_plugin = true
            $plugin_ensure = 'link'
            $file_path     = "${config_root}/plugins/${title}"
            case $target {
                '': {
                    $plugin_target = "${plugin_share_dir}/${title}"
                }
                /^\//: {
                    $plugin_target = $target
                }
                default: {
                    $plugin_target = "${plugin_share_dir}/${target}"
                }
            }
            validate_absolute_path($plugin_target)
        }
        default: {
            $handle_plugin = false
        }
    }

    if $config {
        $config_ensure = $ensure ? {
            'absent'=> absent,
            default => present,
        }
    }
    else {
        $config_ensure = absent
    }


    if $handle_plugin {
        # Install the plugin
        file { $name:
            ensure => $plugin_ensure,
            owner  => 'root',
            group  => $file_group,
            path   => $file_path,
            source => $source,
            target => $plugin_target,
            mode   => '0755',
        }
    }

    # Config

    file{ "${config_root}/plugin-conf.d/${name}.conf":
      ensure  => $config_ensure,
      content => template('munin/plugin_conf.erb'),
    }

}
