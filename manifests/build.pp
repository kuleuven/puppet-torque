# $version should match a valid version from download site
#  http://www.adaptivecomputing.com/support/download-center/torque-download/
# $build_dir is the base directory to download into
# $torque_download_base_url is the base url of download
# $configure_options are any options to use for the configure step
#  you can see all options here http://docs.adaptivecomputing.com/torque/5-1-1/Content/topics/torque/1-installConfig/customizingTheInstall.htm
class torque::build (
	$version 	                = $torque::params::version,
    $build_dir                  = $torque::params::build_dir,
    $torque_download_base_url   = $torque::params::torque_download_base_url,
    $configure_options          = $torque::params::configure_options,
    $prefix                     = $torque::params::prefix
) inherits torque::params {
    include stdlib

    $full_version = "torque-${version}"
    $download_file = "${full_version}.tar.gz"
    $download_url = "${torque_download_base_url}/${download_file}"
    $unpack_dir = "${build_dir}/${full_version}"

    if $configure_options {
        $config_options = join($configure_options, " ")
    } else {
        $config_options = ""
    }

    case $::osfamily {
        'RedHat': {
            $dev_packages = [
                'openssl-devel', 'libxml2-devel', 'boost-devel',
                'gcc', 'gcc-c++', 'hwloc', 'hwloc-devel', 'pam-devel',
                'wget'
            ]
        }
        default: {
            fail("Module ${module_name} is not supported on ${::osfamily}")
        }
    }
    ensure_packages($dev_packages)
    file { "build_dir_${version}":
        path => $build_dir,
        ensure => directory,
        mode => '0700'
    }
    exec {"download_src_${version}":
        command => "/usr/bin/wget ${download_url} -O- | /bin/tar xzvf -",
        creates => $unpack_dir,
        cwd => $build_dir
    }
    exec {"build_${version}":
        command => "${unpack_dir}/configure ${config_options}",
        creates => "${unpack_dir}/Makefile",
        cwd => $unpack_dir
    }
    exec {"make_${version}":
        command => "/usr/bin/make && /bin/touch ${unpack_dir}/make_already_run",
        creates => "${unpack_dir}/make_already_run",
        cwd => $unpack_dir
    }

    exec {"make_packages_${version}":
        command => "/usr/bin/make packages",
        creates => "${unpack_dir}/torque-package-clients-linux-x86_64.sh",
        cwd => $unpack_dir
    }
    exec {"install_torque_docs_${version}":
        command => "${unpack_dir}/torque-package-doc-linux-x86_64.sh --install && /bin/touch ${unpack_dir}/torque_docs_installed",
        require => Exec["make_packages_${version}"],
        creates => "${unpack_dir}/torque_docs_installed"
    }
}
