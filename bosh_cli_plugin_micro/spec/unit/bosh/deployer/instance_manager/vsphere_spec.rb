require 'spec_helper'
require 'bosh/deployer/instance_manager/vsphere'
require 'bosh/deployer/registry'

module Bosh::Deployer
  describe InstanceManager::Vsphere do
    subject(:vsphere) { described_class.new(instance_manager, config, logger) }

    let(:instance_manager) { instance_double('Bosh::Deployer::InstanceManager') }
    let(:config) do
      instance_double(
        'Bosh::Deployer::Configuration',
        cloud_options: {
          'properties' => {
            'registry' => {
            },
            'aws' => {
            },
          },
        },
      )
    end
    let(:logger) { instance_double('Logger') }
    let(:registry) { instance_double('Bosh::Deployer::Registry') }

    before do
    end

    %w(internal_services_ip agent_services_ip client_services_ip).each do |method|
      describe "##{method}" do
        it 'delegates to config' do
          config_result = "fake-#{method}-result"
          expect(config).to receive(method).and_return(config_result)
          expect(vsphere.send(method)).to eq(config_result)
        end
      end
    end
  end
end
