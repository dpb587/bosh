require 'spec_helper'

describe Bosh::Cli::Manifest do

  subject(:manifest) do
    deployment_file = 'fake-deployment-file'
    File.open(deployment_file, 'w') { |f| f.write(YAML.dump(manifest_data)) }
    Bosh::Cli::Manifest.new(deployment_file, director)
  end

  before { manifest.load }

  let(:manifest_data) { {} }
  let(:director) { instance_double('Bosh::Cli::Client::Director') }

  let(:release_list) do
    [
      {
        'release_versions' => [
          {
            'version' => '1',
          },
          {
            'version' => '3.1-dev',
          },
          {
            'version' => '3',
          },
        ],
      },
      {
        'name' => 'bosh',
        'release_versions' => [
          {
            'version' => '2',
          },
          {
            'version' => '1.2-dev',
          },
        ],
      },
    ]
  end

  describe 'resolve_stemcell_aliases' do
    let(:manifest_data) do
      {
        'resource_pools' => [
          {'stemcell' => {'name' => 'foo', 'version' => 'latest'}},
          {'stemcell' => {'name' => 'foo', 'version' => 22}},
          {'stemcell' => {'name' => 'bar', 'version' => 'latest'}},
        ]
      }
    end

    it 'resolves latest alias' do
      stemcells = [
        {'name' => 'foo', 'version' => '22.6.4'},
        {'name' => 'bar', 'version' => '4.1'}
      ]

      expect(director).to receive(:list_stemcells).and_return(stemcells)
      manifest.resolve_stemcell_aliases
      expect(manifest.hash['resource_pools'][0]['stemcell']['version']).to eq('22.6.4')
      expect(manifest.hash['resource_pools'][1]['stemcell']['version']).to eq(22)
      expect(manifest.hash['resource_pools'][2]['stemcell']['version']).to eq('4.1')
    end
  end

  describe '#latest_release_versions' do
    context 'for director version < 1.5' do
      before do
        allow(director).to receive_messages(list_releases: [
              {
                'name' => 'bat',
                'versions' => ['1', '8.2-dev', '2', '8.1-dev'],
              },
              {
                'name' => 'bosh',
                'versions' => ['2', '1.2-dev'],
              },
            ])
      end

      it 'should have the latest version for each release' do
        expect(manifest.latest_release_versions).to eq({
              'bat' => '8.2-dev',
              'bosh' => '2'
            })
      end
    end

    context 'for director version >= 1.5' do
      before { allow(director).to receive_messages(list_releases: [
            {
              'name' => 'bat',
              'versions' => ['1', '8.2-dev', '8+dev.3', '2', '8+dev.1'],
            },
            {
              'name' => 'bosh',
              'versions' => ['2', '1.2-dev'],
            },
          ])
      }

      it 'should have the latest version for each release' do
        expect(manifest.latest_release_versions).to eq({
              'bat' => '8+dev.3',
              'bosh' => '2'
            })
      end
    end
  end

  describe '#resolve_release_aliases' do
    context 'when release versions are explicit' do
      context 'when manifest has single release' do
        let(:manifest_data) do
          {
            'release' => {
              'version' => '3.1-dev'
            }
          }
        end

        it 'should leave the version as is' do
          expect(manifest.hash['release']['version']).to eq('3.1-dev')
        end
      end

      context 'manifest with multiple releases' do
        let(:manifest_data) do
          {
            'releases' => [
              { 'name' => 'bat', 'version' => '3.1-dev' },
              { 'name' => 'bosh', 'version' => '1.2-dev' },
            ]
          }
        end

        it 'should leave the versions as they are' do
          expect(manifest.hash['releases'].detect { |release| release['name'] == 'bat' }['version']).to eq('3.1-dev')
          expect(manifest.hash['releases'].detect { |release| release['name'] == 'bosh' }['version']).to eq('1.2-dev')
        end
      end
    end

    context "when some release versions are set to 'latest'" do
      let(:manifest_data) do
        {
          'releases' => [
            { 'name' => 'bat', 'version' => '3.1-dev' },
            { 'name' => 'bosh', 'version' => 'latest' },
          ]
        }
      end
      before do
        allow(director).to receive_messages(list_releases: release_list)
      end

      it 'should resolve the version to the latest for that release' do
        manifest.resolve_release_aliases
        expect(manifest.hash['releases'].detect { |release| release['name'] == 'bat' }['version']).to eq('3.1-dev')
        expect(manifest.hash['releases'].detect { |release| release['name'] == 'bosh' }['version']).to eq('2')
      end

      context 'when the release is not found on the director' do
        let(:release_list) { [] }

        it 'raises an error' do
          expect {
            manifest.resolve_release_aliases
          }.to raise_error(
            )
        end
      end
    end
  end
end
