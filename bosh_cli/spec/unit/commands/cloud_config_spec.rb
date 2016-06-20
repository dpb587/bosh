require 'spec_helper'

describe Bosh::Cli::Command::CloudConfig do
  let(:director) { double(Bosh::Cli::Client::Director) }
  let(:runner) { instance_double('Bosh::Cli::Runner') }
  subject(:cloud_config_command) { described_class.new(nil, director) }

  before { @config = Support::TestConfig.new(cloud_config_command) }

  before :each do
    target = 'https://127.0.0.1:8080'

    config = @config.load


    cloud_config_command.add_option(:target, target)
    cloud_config_command.add_option(:username, 'user')
    cloud_config_command.add_option(:password, 'pass')

    stub_request(:get, "#{target}/info").to_return(body: '{}')
  end

  before(:each) do
  end

  it "show outputs latest cloud config" do
    expect(director).to receive(:get_cloud_config)
    cloud_config_command.show
  end

  it "shows success when successfully updating cloud config" do
    allow(cloud_config_command).to receive(:read_yaml_file).and_return("something")
    expect(director).to receive(:update_cloud_config).with("something").and_return(true)
    expect(cloud_config_command).to receive(:say).with("Successfully updated cloud config")
    cloud_config_command.update("/path/to/alpha.yml")
  end

  it "shows error when failing to update cloud config" do
    allow(cloud_config_command).to receive(:read_yaml_file).and_return("something")
    expect(director).to receive(:update_cloud_config).with("something").and_return(false)
    expect{cloud_config_command.update("/path/to/alpha.yml")}.to raise_error(Bosh::Cli::CliError, "Failed to update cloud config")
  end
end