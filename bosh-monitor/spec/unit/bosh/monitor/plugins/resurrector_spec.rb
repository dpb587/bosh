require 'spec_helper'

describe 'Bhm::Plugins::Resurrector' do
  include Support::UaaHelpers

  let(:options) {
    {
      'director' => {
        'endpoint' => 'http://foo.bar.com:25555',
        'user' => 'user',
        'password' => 'password',
        'client_id' => 'client-id',
        'client_secret' => 'client-secret',
        'ca_cert' => 'ca-cert'
      }
    }
  }
  let(:plugin) { Bhm::Plugins::Resurrector.new(options) }
  let(:uri) { 'http://foo.bar.com:25555' }
  let(:status_uri) { "#{uri}/info" }

  before do
    stub_request(:get, status_uri).
      to_return(status: 200, body: JSON.dump({'user_authentication' => user_authentication}))
  end

  let(:alert) { Bhm::Events::Base.create!(:alert, alert_payload(deployment: 'd', job: 'j', instance_id: 'i')) }

  let(:user_authentication) { {} }

  it 'should construct a usable url' do
    expect(plugin.url.to_s).to eq(uri)
  end

  context 'when the event machine reactor is not running' do
    it 'should not start' do
      expect(plugin.run).to be(false)
    end
  end

  context 'when the event machine reactor is running' do
    around do |example|
      EM.run do
        EM.stop
      end
    end

    context 'alerts with deployment, job and id' do

      before do
        expect(Bhm::Plugins::ResurrectorHelper::AlertTracker).to receive(:new).and_return(@don)
      end

      it 'should be delivered' do
        expect(@don).to receive(:melting_down?).and_return(false)

        request_data = {
            head: {
            },
        }
        expect(plugin).to receive(:send_http_put_request).with(request_url, request_data)

      end

      context 'when auth provider is using UAA token issuer' do
        let(:user_authentication) do
          {
            'options' => {
            }
          }
        end

        before do


          allow(CF::UAA::TokenIssuer).to receive(:new).with(
          ).and_return(token_issuer)
        end

        it 'uses UAA token' do
          expect(@don).to receive(:melting_down?).and_return(false)

          request_data = {
            head: {
            },
          }
          expect(plugin).to receive(:send_http_put_request).with(request_url, request_data)

        end
      end

      it 'does not deliver while melting down' do
        expect(@don).to receive(:melting_down?).and_return(true)
        expect(plugin).not_to receive(:send_http_put_request)
      end

      it 'should alert through EventProcessor while melting down' do
        expect(@don).to receive(:melting_down?).and_return(true)
        expected_time = Time.new
        allow(Time).to receive(:now).and_return(expected_time)
        alert_option = {
            :created_at => expected_time.to_i
        }
        expect(event_processor).to receive(:process).with(:alert, alert_option)
      end
    end

    context 'alerts without deployment, job and id' do

      it 'should not be delivered' do

        expect(plugin).not_to receive(:send_http_put_request)

      end
    end

    context 'when director status is not 200' do
      before do
      end

      it 'returns false' do

        expect(plugin).not_to receive(:send_http_put_request)

      end

      context 'when director starts responding' do
        before do
        end

        it 'starts sending alerts' do

          expect(plugin).to receive(:send_http_put_request).once

        end
      end
    end
  end
end
