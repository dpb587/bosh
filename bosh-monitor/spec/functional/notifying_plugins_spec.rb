require 'spec_helper'
require 'timecop'

class FakeNATS
  def initialize(verbose=false)
    @subscribers = []
  end

  def subscribe(channel, &block)
    @subscribers << block
  end

  def alert(message)
    reply = 'reply'
    subject = '1.2.3.not-an-agent'

    @subscribers.each do |subscriber|
      subscriber.call(message, reply, subject)
    end
  end
end

describe 'notifying plugins' do
  WebMock.allow_net_connect!

  let(:runner) { Bosh::Monitor::Runner.new(spec_asset('dummy_plugin_config.yml')) }

  before do
    free_port = find_free_tcp_port
  end

  context 'when alert is received via nats' do
    it 'sends an alert to its plugins' do
      payload = {
        'id' => 'payload-id',
        'severity' => 3,
        'title' => 'payload-title',
        'summary' => 'payload-summary',
        'created_at' => Time.now.to_i,
      }

      called = false
      alert = nil
      EM.run do
        nats = FakeNATS.new
        allow(NATS).to receive(:connect).and_return(nats)
        runner.run
        nats.alert(JSON.dump(payload))
        EM.add_periodic_timer(0.1) do
          alert = get_alert
          called = true
          EM.stop if alert && alert.attributes.match(payload)
        end
      end

      expect(alert).to_not be_nil
      expect(alert.attributes).to eq(payload)
      expect(called).to be(true)
    end
  end

  context 'when health monitor fails to fetch deployments' do
    # director is not running

    before do
      created_at_time = Time.now
    end

    it 'sends an alert to its plugins' do
      allow(SecureRandom).to receive(:uuid).and_return('random-id')
      alert_json = {
        'id' => 'random-id',
        'severity' => 3,
        'title' => 'Health monitor failed to connect to director',
        'summary' => /Cannot get status from director/,
        'created_at' => Time.now.to_i,
        'source' => 'hm'
      }

      called = false
      alert = nil
      EM.run do
        nats = FakeNATS.new
        allow(NATS).to receive(:connect).and_return(nats)
        runner.run
        EM.add_periodic_timer(0.1) do
          alert = get_alert
          called = true
          EM.stop if alert && alert.attributes.match(alert_json)
        end
      end

      expect(alert).to_not be_nil
      expect(alert.attributes).to match(alert_json)
      expect(called).to be(true)
    end
  end

  def start_fake_nats
  end

  def wait_for_plugins(tries=60)
    while tries > 0
      # wait for alert plugin to load
    end
  end

  def get_alert
    dummy_plugin = Bosh::Monitor.event_processor.plugins[:alert].first
    return dummy_plugin.events.first if dummy_plugin.events
  end
end
