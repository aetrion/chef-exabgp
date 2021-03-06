resource_name :exabgp

property :instance, [String, false], name_property: true
property :install_type, Symbol, default: :pip
property :package_version, String, default: lazy { node['exabgp']['package_version'] }
property :cookbook, String, default: 'exabgp'
property :variables, Hash

include ExabgpCookbook::Helpers

action :install do
  ::Chef::Log.warn '***EXABGP COOKBOOK DEPRECATION NOTICE!*** The exabgp resource will be replaced by exabgp_install and exabgp_config in a future release. It will also only support Chef 13.10+ so please pin your version now to avoid issues in the very near future! See README for migration details.'

  case new_resource.install_type
  when :package
    package 'exabgp' do
      action :install
      version new_resource.package_version if new_resource.package_version
    end
  when :pip
    python_runtime '2' do
      # TODO: remove this when pip 10 is supported https://github.com/poise/poise-python/pull/108
      pip_version '9.0.3'
    end

    python_package 'exabgp' do
      action :install
      version new_resource.package_version if new_resource.package_version
    end
  when :source
    package 'git-core'

    git '/usr/src/exabgp' do
      repository node['exabgp']['source_url']
      reference node['exabgp']['source_version']
      action :sync
    end

    node.default['exabgp']['bin_path'] = '/usr/src/exabgp/sbin/exabgp'
  end

  directory "/etc/#{installation_name(new_resource.instance)}"

  template "/etc/#{installation_name(new_resource.instance)}/exabgp.conf" do
    cookbook new_resource.cookbook
    source 'exabgp.conf.erb'
    variables(new_resource.variables)
    mode 0644
  end

  unless new_resource.instance
    node.default['exabgp']['config_path'] = "/etc/#{installation_name(new_resource.instance)}/exabgp.conf"
  end
end
