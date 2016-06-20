require 'spec_helper'

describe Bosh::Cli::Command::Disks do
  subject(:command) { described_class.new }

  before do
    allow(command).to receive_messages(director: director, logged_in?: true, nl: nil, say: nil)

    command.options[:orphaned] = true
  end
  let(:director) { double(Bosh::Cli::Client::Director) }

  describe 'list' do
    let(:orphaned_disk_1) do
      {
        'disk_cid' => 'disk_1_cid',
        'deployment_name' => 'deployment_1',
        'instance_name' => 'instance_1',
        'orphaned_at' => '2012-11-10'
      }
    end
    let(:orphaned_disk_2) do
      {
        'disk_cid' => 'disk_2_cid',
        'size' => 20,
        'deployment_name' => 'deployment_2',
        'instance_name' => 'instance_2',
        'az' => 'az2',
        'orphaned_at' => '2012-12-10'
      }
    end

    context 'when there are multiple orphaned disks' do
      before { expect(director).to receive(:list_orphan_disks) { [orphaned_disk_1, orphaned_disk_2] } }

      it 'lists all orphaned disks' do
        expect(command).to receive(:say) do |display_output|
          expect(display_output.render).to include(<<DISKS)
DISKS
        end

        command.list
      end
    end

    context 'when there no orphaned disks' do
      before { expect(director).to receive(:list_orphan_disks) { [] } }

      it 'displays a message telling the user that there are no orphaned disks' do
        expect(command).to receive(:say) do |display_output|
          expect(display_output).to include('No orphaned disks')
        end

        command.list
      end
    end
  end
end
