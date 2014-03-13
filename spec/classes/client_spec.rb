require 'spec_helper'

describe 'torque::client' do

  let(:facts) {{
    :operatingsystem => 'Debian',
    :osfamily        => 'Debian',
    :lsbdistcodename => 'wheezy',
    :lsbdistid       => 'Debian',
    :processorcount  => 2,
  }}

  let(:params){{
    :server_name => 'foo.bar'
  }}

  it { should contain_class('torque::client') }
  it { should contain_class('torque::mom') }

  it { should contain_package('torque-mom').with(
        :ensure => 'installed'
  )}

  it { should contain_package('torque-client').with(
        :ensure => 'installed'
  )}

  # on Debian/Ubuntu it's torque-mom, some other distributions
  # maybe pbs_mom
  it { should contain_service('torque-mom').with(
        :ensure => 'running',
        :enable => true
  )}

  it {
    should contain_file(
      '/etc/torque/server_name'
    ).with({
    'ensure'  => 'present',
    'owner'   => 'root',
    'group'   => 'root',
    'mode'    => '0644',
    }).with_content(/foo.bar/)
  }
end