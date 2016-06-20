require 'spec_helper'

module Bosh::Cli::Command::Release
  describe ListReleases do
    subject(:command) { described_class.new }

    let(:director) do
      instance_double(
        'Bosh::Cli::Client::Director',
      )
    end

    let(:actual) { Bosh::Cli::Config.output.string }

    before do
      allow(command).to receive(:director).and_return(director)
      allow(command).to receive(:show_current_state)
    end

    describe '#list' do
      let(:releases) do
        [
          {
            'name' => 'bosh-release',
            'release_versions' => [
              {
                'version' => '0+dev.3',
                'commit_hash' => 'fake-hash-3',
                'uncommitted_changes' => true
              },
              {
                'version' => '0+dev.2',
                'commit_hash' => 'fake-hash-2',
                'currently_deployed' => true,
              },
              {
                'version' => '0+dev.1',
                'commit_hash' => 'fake-hash-1',
              }
            ],
          }
        ]
      end

      before do
        allow(command).to receive(:logged_in?).and_return(true)
        allow(director).to receive(:list_releases).and_return(releases)
      end

      it 'lists all releases' do
        command.list
        expect(actual).to match_output %(

        )
      end

      context 'when there is a deployed release' do
        let(:releases) do
          [
            {
              'name' => 'bosh-release',
              'release_versions' => [
                {
                  'version' => '0+dev.3',
                  'commit_hash' => 'fake-hash-3',
                  'currently_deployed' => true,
                }
              ],
            }
          ]
        end

        it 'prints Currently deployed' do
          command.list
          expect(actual).to match_output %(

          )
        end
      end

      context 'when there are releases with uncommited changes' do
        let(:releases) do
          [
            {
              'name' => 'bosh-release',
              'release_versions' => [
                {
                  'version' => '0+dev.3',
                  'commit_hash' => 'fake-hash-3',
                  'uncommitted_changes' => true
                }
              ],
            }
          ]
        end

        it 'prints Uncommited changes' do
          command.list
          expect(actual).to match_output %(

          )
        end
      end

      context 'when there are releases with unknown version' do
        let(:releases) do
          [
            {
              'name' => 'bosh-release',
              'release_versions' => []
            }
          ]
        end

        it 'prints Uncommited changes' do
          command.list
          expect(actual).to match_output %(

          )
        end
      end
    end
  end
end
