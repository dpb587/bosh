require 'spec_helper'

module Bosh::Director
  describe DeploymentPlan::GlobalNetworkResolver do
    subject(:global_network_resolver) { DeploymentPlan::GlobalNetworkResolver.new(current_deployment, director_ips, logger) }
    let(:runtime_config) { nil }
    let(:cloud_config) { nil }
    let(:director_ips) { [] }
    let(:current_deployment) do
      deployment_model = Models::Deployment.make(
        cloud_config: cloud_config,
      )
      DeploymentPlan::Planner.new(
        {name: 'current-deployment', properties: {}},
        '',
        cloud_config,
        runtime_config,
        deployment_model
      )
    end

    describe '#reserved_ranges' do
      it "ignores deployments that don't have a manifest" do
        Models::Deployment.make(
        )

        reserved_ranges = global_network_resolver.reserved_ranges
        expect(reserved_ranges).to be_empty
      end

      describe 'when initialized with director ips' do
        let(:director_ips) { ['192.168.1.11', '10.10.0.4'] }
        describe 'when using global networking' do
          let(:cloud_config) { Models::CloudConfig.make }

          it 'returns the director IPs as ranges' do
            expect(global_network_resolver.reserved_ranges).to contain_exactly(
              NetAddr::CIDR.create('192.168.1.11/32'),
              NetAddr::CIDR.create('10.10.0.4/32'),
            )
          end
        end

        describe 'when not using global networking' do
          it 'returns an empty set' do
            expect(global_network_resolver.reserved_ranges).to be_empty
          end
        end
      end

      context 'when deploying with cloud config after legacy deployments' do
        let(:cloud_config) do
          Models::CloudConfig.make({
            manifest: {
              'networks' => [{
                'subnets' => [
                  {
                  }
                ]
              }]
            }
          })
        end

        context 'when two different legacy deployments reserved ranges overlap' do
          before do
            Models::Deployment.make(
              manifest: Psych.dump({
                'networks' => [{
                  'subnets' => [{
                    'range' => '10.10.0.0/24',
                  }],
                }],
              })
            )
            Models::Deployment.make(
              manifest: Psych.dump({
                'networks' => [{
                  'subnets' => [{
                    'range' => '10.10.0.0/24',
                  }],
                }],
              })
            )
          end

          it 'returns reserved ranges' do
            expect(global_network_resolver.reserved_ranges).not_to be_empty
          end
        end

        context 'when the legacy deployment reserved range is overlaps with itself' do
          before do
            Models::Deployment.make(
                manifest: Psych.dump({
                   'networks' => [{
                        'subnets' => [{
                            'range' => '10.10.0.0/24',
                        }],
                    }],
                 })
            )
          end

          it 'returns reserved ranges' do
            expect(global_network_resolver.reserved_ranges).not_to be_empty
          end
        end
      end

      context 'when current deployment is using cloud config' do
        let(:cloud_config) { Models::CloudConfig.make }

        it 'excludes networks from deployments with cloud config' do
          Models::Deployment.make(
            cloud_config: cloud_config,
            manifest: Psych.dump({
                'networks' => [{
                    'subnets' => [{
                      }],
                  }],
              })
          )
          expect(global_network_resolver.reserved_ranges).to be_empty
        end

        context 'when have legacy deployments' do
          before do
            Models::Deployment.make(
              manifest: Psych.dump({
                'networks' => [
                  {
                    'subnets' => [{
                      'range' => '192.168.0.0/28',
                      'reserved' => [
                        '192.168.0.0-192.168.0.5',
                        '192.168.0.7',
                        '192.168.0.11-192.168.0.12'
                      ],
                    }],
                  },
                  {
                    'subnets' => [{
                      'range' => '192.168.1.0/24',
                    }],
                  }
                ],
              })
            )

            Models::Deployment.make(
              manifest: Psych.dump({
                'networks' => [{
                  'subnets' => [{
                    'range' => '192.168.2.0/24',
                  }],
                }],
              })
            )

            Models::Deployment.make(
              manifest: Psych.dump({
                'networks' => [{
                  'type' => 'dynamic',
                }],
              })
            )

            Models::Deployment.make(
              cloud_config: cloud_config,
              manifest: Psych.dump({
                'networks' => [{
                  'subnets' => [{
                  }],
                }],
              })
            )
          end

          it 'returns manual network ranges from legacy deployments (deployments with no cloud config)' do
            reserved_ranges = global_network_resolver.reserved_ranges
            expect(reserved_ranges).to contain_exactly(
              NetAddr::CIDR.create('192.168.0.6/32'),
              NetAddr::CIDR.create('192.168.0.8/31'),
              NetAddr::CIDR.create('192.168.0.10/32'),
              NetAddr::CIDR.create('192.168.0.13/32'),
              NetAddr::CIDR.create('192.168.0.14/31'),
              NetAddr::CIDR.create('192.168.1.1/24'),
              NetAddr::CIDR.create('192.168.2.1/24'),
            )
          end

          it 'logs used ip address ranges in a nice format' do

            expect(logger).to receive(:info).with('Following networks and individual IPs are reserved by non-cloud-config deployments: ' +
                    '192.168.0.6, 192.168.0.8-192.168.0.10, 192.168.0.13-192.168.0.15, 192.168.1.0-192.168.2.255')
            global_network_resolver.reserved_ranges
          end

          context 'when director ips has values' do
            let(:director_ips) { ['192.168.1.11', '10.10.0.4'] }
            it 'logs the director ips as ranges too'  do
              expect(logger).to receive(:info).with('Following networks and individual IPs are reserved by non-cloud-config deployments: ' +
                '10.10.0.4, 192.168.0.6, 192.168.0.8-192.168.0.10, 192.168.0.13-192.168.0.15, 192.168.1.0-192.168.2.255')
              global_network_resolver.reserved_ranges
            end
          end
        end
      end

      context 'when current deployment is not using cloud config' do

        before do
          Models::Deployment.make(
            manifest: Psych.dump({
                'networks' => [{
                    'subnets' => [{
                      }],
                  }],
              })
          )
        end

        it 'is empty' do
          expect(global_network_resolver.reserved_ranges).to be_empty
        end
      end
    end
  end
end
