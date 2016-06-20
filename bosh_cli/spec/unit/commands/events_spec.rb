require 'spec_helper'

describe Bosh::Cli::Command::Events do
  subject(:command) { described_class.new }

  before do
    allow(command).to receive_messages(director: director, logged_in?: true, nl: nil, say: nil)
  end

  let(:director) { double(Bosh::Cli::Client::Director) }
  let(:target) { 'http://example.org' }

  describe '#list' do
    let(:event_1) do
      {
        'id' => '1',
        'timestamp' => 1455635708,
        'user' => 'admin',
        'action' => 'create',
        'object_type' => 'deployment',
        'object_name' => 'depl1',
        'task' => '1',
        'context' => {}
      }
    end
    let(:event_2) do
      {
        'id' => '2',
        'parent_id' => '1',
        'timestamp' => 1455635708,
        'user' => 'admin',
        'action' => 'create',
        'object_type' => 'deployment',
        'object_name' => 'depl1',
        'task' => '5',
        'context' => {'information' => 'blah blah'}
      }
    end
    let(:event_3) do
      {
        'id' => '3',
        'timestamp' => 1455635708,
        'user' => 'admin',
        'action' => 'rename',
        'error' => 'Someting went wrong',
        'object_type' => 'deployment',
        'object_name' => 'depl1',
        'task' => '6',
        'context' => {'new name' => 'depl2'}
      }
    end
    let(:events) { [event_3, event_2, event_1] }

    context 'when there are events' do
      before { expect(director).to receive(:list_events) { events } }

      it 'lists all events' do
        expect(command).to receive(:say) do |display_output|
          expect(display_output.to_s).to match_output '
'
        end
        command.list
      end
    end

    context 'when filtering events by deployment name' do
      before { expect(director).to receive(:list_events).with({target: target, deployment: 'deployment-name'}) { [] } }

      it 'should invoke the director with the right options' do
        command.options = {deployment: 'deployment-name', target: target}
        command.list
      end
    end

    context 'when filtering events by task name' do
      before { expect(director).to receive(:list_events).with({target: target, task: '1'}) { [] } }

      it 'should invoke the director with the right options' do
        command.options = {task: '1', target: target}
        command.list
      end
    end

    context 'when filtering events by before timestamp' do
      before { expect(director).to receive(:list_events).with({target: target, before: 'Tue Feb 16 15:15:08 UTC 2016'}) { [] } }

      it 'should invoke the director with the right options' do
        command.options = {before: 'Tue Feb 16 15:15:08 UTC 2016', target: target}
        command.list
      end
    end

    context 'when filtering events by after timestamp' do
      before { expect(director).to receive(:list_events).with({target: target, after: 'Tue Feb 16 15:15:08 UTC 2016'}) { [] } }

      it 'should invoke the director with the right options' do
        command.options = {after: 'Tue Feb 16 15:15:08 UTC 2016', target: target}
        command.list
      end
    end

    context 'when filtering events by instance jobname/id' do
      before { expect(director).to receive(:list_events).with({target: target, instance: 'job/1'}) { [] } }

      it 'should invoke the director with the right options' do
        command.options = {instance: 'job/1', target: target}
        command.list
      end
    end

    context 'when there no events' do
      before { expect(director).to receive(:list_events) { [] } }

      it 'displays a message telling the user that there are no events' do
        expect(command).to receive(:say) do |display_output|
          expect(display_output).to include('No events')
        end
        command.list
      end
    end

    it 'can list events before a given id' do
      expect(director).to receive(:list_events).with({before_id: 2, target: target}).and_return([event_1])
      expect(command).to receive(:say) do |display_output|
        expect(display_output.to_s).to match_output '
        '
      end
      command.options = {before_id: 2, target: target}
      command.list
    end
  end
end
