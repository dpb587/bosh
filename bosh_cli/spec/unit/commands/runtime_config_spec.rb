require 'spec_helper'

describe Bosh::Cli::Command::RuntimeConfig do
  let(:director) { double(Bosh::Cli::Client::Director) }
  let(:runner) { instance_double('Bosh::Cli::Runner') }
  subject(:runtime_config_command) { described_class.new(nil, director) }

  before { @config = Support::TestConfig.new(runtime_config_command) }

  before :each do
    target = 'https://127.0.0.1:8080'

    config = @config.load


    runtime_config_command.add_option(:target, target)
    runtime_config_command.add_option(:username, 'user')
    runtime_config_command.add_option(:password, 'pass')

    stub_request(:get, "#{target}/info").to_return(body: '{}')
  end

  before(:each) do
  end

  it "show outputs latest runtime config" do
    expect(director).to receive(:get_runtime_config)
    runtime_config_command.show
  end

  it "shows success when successfully updating runtime config" do
    allow(runtime_config_command).to receive(:read_yaml_file).and_return("something")
    expect(director).to receive(:update_runtime_config).with("something").and_return(true)
    expect(runtime_config_command).to receive(:say).with("Successfully updated runtime config")
    runtime_config_command.update("/path/to/alpha.yml")
  end

  it "shows error when failing to update runtime config" do
    allow(runtime_config_command).to receive(:read_yaml_file).and_return("something")
    expect(director).to receive(:update_runtime_config).with("something").and_return(false)
    expect{runtime_config_command.update("/path/to/alpha.yml")}.to raise_error(Bosh::Cli::CliError, "Failed to update runtime config")
  end
end