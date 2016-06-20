require "spec_helper"

describe Bosh::AwsCliPlugin::Migration do
  let(:config) do
    {"aws" => {}}
  end

  let(:s3) { double("S3") }
  let(:receipt) do
  end

  before do
    allow(Bosh::AwsCliPlugin::S3).to receive_messages(new: s3)
  end

  around do |example|
    Dir.mktmpdir do |tmpdir|
      Dir.chdir(tmpdir) do
      end
    end
  end

  it "saves receipts in s3" do
    expect(s3).to receive(:upload_to_bucket).with("bucket", "receipts/aws_dummy_receipt.yml", YAML.dump(receipt))

  end

  it "saves receipts in the local filesystem" do

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do

        expect(receipt_contents).to eq(receipt)
      end
    end
  end

  it "loads the receipt from S3" do
    expect(s3).to receive(:fetch_object_contents).with("bucket", "receipts/aws_dummy_receipt.yml").and_return(YAML.dump(receipt))

    expect(migration.load_receipt("aws_dummy_receipt")).to eq(receipt)
  end

  it "initializes AWS helpers" do

    expect(Bosh::AwsCliPlugin::S3).to receive(:new).with(config["aws"]).and_return(s3)
    expect(Bosh::AwsCliPlugin::ELB).to receive(:new).with(config["aws"]).and_return(elb)
    expect(Bosh::AwsCliPlugin::EC2).to receive(:new).with(config["aws"]).and_return(ec2)
    expect(Bosh::AwsCliPlugin::Route53).to receive(:new).with(config["aws"]).and_return(route53)

    expect(migration.ec2).to eq(ec2)
    expect(migration.s3).to eq(s3)
    expect(migration.elb).to eq(elb)
    expect(migration.route53).to eq(route53)
    expect(migration.logger).not_to be_nil
  end
end
