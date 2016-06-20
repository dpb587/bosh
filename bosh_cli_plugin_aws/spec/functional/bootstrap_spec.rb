require 'spec_helper'

describe 'AWS Bootstrap commands' do
  let(:aws) { Bosh::Cli::Command::AWS.new }
  let(:mock_s3) { double(Bosh::AwsCliPlugin::S3) }
  let(:bosh_config)  { File.expand_path(File.join(File.dirname(__FILE__), '..', 'assets', 'bosh_config.yml')) }
  let(:arch) { Bosh::Stemcell::Arch.ppc64le? ? 'ppc64le-' : ''}

  before do
    aws.options[:non_interactive] = true

    allow(aws).to receive(:s3).and_return(mock_s3)
  end

  around do |example|

    @bosh_config = Tempfile.new('bosh_config')
    FileUtils.cp(bosh_config, @bosh_config.path)
    aws.add_option(:config, @bosh_config.path)

    FileUtils.cp(asset('id_spec_rsa'), '/tmp/somekey')

    Dir.mktmpdir do |dirname|
      Dir.chdir dirname do
        FileUtils.cp(asset('test-output.yml'), 'aws_vpc_receipt.yml')
        FileUtils.cp(asset('test-aws_route53_receipt.yml'), 'aws_route53_receipt.yml')
        FileUtils.cp(asset('test-aws_rds_bosh_receipt.yml'), 'aws_rds_bosh_receipt.yml')

      end
    end


  end

  describe 'aws bootstrap micro' do
    context 'when non-interactive' do

      before do
      end

      it 'should bootstrap microbosh' do

        expect(SecureRandom).to receive(:base64).and_return('hm_password')
        expect(SecureRandom).to receive(:base64).and_return('admin_password')

        expect(login_command).to receive(:login).with('admin', 'admin')
        expect(user_command).to receive(:create).with('admin', 'admin_password').and_return(true)
        expect(login_command).to receive(:login).with('admin', 'admin_password')
        expect(user_command).to receive(:create).with('hm', 'hm_password').and_return(true)
        expect(login_command).to receive(:login).with('hm', 'hm_password')

        expect_any_instance_of(Bosh::Deployer::InstanceManager).to receive(:with_lifecycle)


        expect(stemcell_ami_request).to have_been_made
      end

      context 'hm user and password' do
        before do
        end

        it "creates default 'hm' user name for hm" do

          expect(fake_bootstrap).to receive(:create_user).with('hm', anything)
        end

        it 'passes the generated hm user to the new microbosh bootstrapper' do
          expect(Bosh::AwsCliPlugin::MicroBoshBootstrap).to receive(:new) do |_, options|
            expect(options[:hm_director_user]).to eq('hm')
            expect(options[:hm_director_password]).to eq('some_password')
          end
        end

        it 'creates a hm user with name from options' do
          expect(fake_bootstrap).to receive(:create_user).with('hm_guy', anything)
        end
      end

    end

    context 'when interactive' do
      before do

      end

      it 'should ask for a new user' do

        expect(aws).to receive(:ask).with('Enter username: ').and_return('admin')
        expect(aws).to receive(:ask).with('Enter password: ').and_return('admin_passwd')
        expect(fake_bootstrap).to receive(:create_user).with('admin', 'admin_passwd')
        expect(fake_bootstrap).to receive(:create_user).with('hm', anything)

      end
    end
  end

  describe 'aws bootstrap bosh' do

    let(:deployments) do
      [
          {
          }
      ]
    end

    before do


    end

    context 'when the target is not set' do
      before do
      end

      it 'raises an error' do
        expect { aws.bootstrap_bosh }.to raise_error(/Please choose target first/)
      end
    end

    context 'when the target already has a release, possibly a stemcell' do
      before do

        releases = [
            {
                'release_versions' => [
                    {
                    }
                ]
            }
        ]


        # Skip the actual deploy, since we already test it later on

      end

      it 'use the existent release' do
        expect(mock_s3).not_to receive(:copy_remote_file)
        expect(Bosh::Exec).not_to receive(:sh).with('bundle exec rake release:create_dev_release')
        expect_any_instance_of(Bosh::Cli::Command::Release::UploadRelease).not_to receive(:upload)

        expect do
        end.to_not raise_error
      end

      it 'use the existent stemcell' do
        expect(mock_s3).not_to receive(:copy_remote_file)
        expect_any_instance_of(Bosh::Cli::Command::Stemcell).not_to receive(:upload)
        expect do
        end.to_not raise_error
      end

      context 'when the target has no stemcell' do
        it 'uploads a stemcell' do
          expect(mock_s3).to receive(:copy_remote_file).and_return '/tmp/bosh_stemcell.tgz'
          expect(Bosh::Stemcell::Archive).to receive(:new).with('/tmp/bosh_stemcell.tgz').and_return(stemcell_archive)
          expect_any_instance_of(Bosh::Cli::Command::Stemcell).to receive(:upload)
        end
      end
    end

    context 'when the target already have a deployment' do
      # This deployment name comes from test-output.yml asset file.

      before do



      end

      it 'bails telling the user this command is only useful for the initial deployment' do
        expect { aws.bootstrap_bosh }.to raise_error(/Deployment '#{deployment_name}' already exists\./)
      end
    end

    context 'when the prerequisites are all met' do

      before do
        expect(mock_s3).to receive(:copy_remote_file).with('bosh-jenkins-artifacts',"bosh-stemcell/aws/light-bosh-stemcell-#{arch}latest-aws-xen-ubuntu-trusty-go_agent.tgz",'bosh_stemcell.tgz').and_return(stemcell_stub)
        expect(mock_s3).to receive(:copy_remote_file).with('bosh-jenkins-artifacts', /release\/bosh-(.+)\.tgz/,'bosh_release.tgz').and_return('bosh_release.tgz')



        # FIXME This should be read from the bosh_config.yml file
        # but for some reason, auth is not being read properly

        # Verify deployment's existence


          to_return(
          )



        # Stub out the release creation to make the tests MUCH faster,
        # instead of actually building the tarball.
        expect_any_instance_of(Bosh::Cli::Command::Release::UploadRelease).to receive(:upload)



        # Checking for previous deployments properties from the receipt file.

        # Checking for previous deployment manifest


        new_target_info = {
        }


        expect(aws).to receive(:ask).with('Enter username: ').and_return(username)
        expect(aws).to receive(:ask).with('Enter password: ').and_return(password)


      end

      it 'generates an updated manifest for bosh' do
        expect(File.exist?('deployments/bosh/bosh.yml')).to be(false)
        expect(File.exist?('deployments/bosh/bosh.yml')).to be(true)
      end

      it 'runs deployment diff' do

        expect(generated_manifest).to include('# Fake network properties to satisfy bosh diff')
      end

      it 'uploads the latest stemcell' do

        expect(@stemcell_upload_request).to have_been_made
      end

      it 'deploys bosh' do

        expect(@deployment_request).to have_been_made
      end

      it 'sets the target to the new bosh' do

        expect(config['target']).to eq('https://50.200.100.3:25555')
      end

      it 'creates a new user in new bosh' do

        expect(a_request(:get, 'https://50.200.100.3:25555/info').with(
            :headers => {
            })).to have_been_made.times(4)

        expect(@create_user_request).to have_been_made

        expect(a_request(:get, 'https://50.200.100.3:25555/info').with(
            :headers => {
            })).to have_been_made.once
      end

      it 'creates a new hm user in bosh' do
        expect(@create_hm_user_req).to have_been_made.once
      end
    end
  end
end
