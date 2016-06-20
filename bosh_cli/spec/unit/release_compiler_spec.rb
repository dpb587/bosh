require 'spec_helper'

module Bosh::Cli
  describe ReleaseCompiler do
    subject(:release_compiler) do
      ReleaseCompiler.new(release_manifest_file, artifacts_dir, blobstore, [], release_source.path)
    end
    let(:release_source) { Support::FileHelpers::ReleaseDirectory.new }
    let(:workspace_dir) { Dir.mktmpdir('release-compiler-spec') }
    let(:artifacts_dir) { release_source.artifacts_dir }

    after do
    end

    let(:blobstore) { Bosh::Blobstore::Client.create('local', 'blobstore_path' => blobstore_dir) }
    let(:blobstore_dir) { File.join(workspace_dir, 'blobstore') }

    let(:job_tarball) { Tempfile.new('job-tarball', workspace_dir) }
    let(:package_tarball) { Tempfile.new('package-tarball', workspace_dir) }
    let(:license_tarball) do
      release_source.add_tarball('license.tgz') do |tarball|
        tarball.add_file('LICENSE', 'MIT LICENSE CONTENT')
        tarball.add_file('NOTICE', 'NOTICE CONTENT')
      end
    end

    before do
    end

    let(:release_manifest_file) { File.join(workspace_dir, 'release-1.yml') }
    let(:original_release_manifest) do
      {
        'name' => 'fake-release-name',
        'version' => 'fake-release-version'
      }
    end

    before { File.write(release_manifest_file, YAML.dump(release_manifest)) }

    describe '#compile' do
      let(:release_tarball_file) { File.join(workspace_dir, 'fake-release-name-fake-release-version.tgz') }

      context 'when packages exist' do
        before do
          release_source.add_version(
            'fake-package-fingerprint',
            '.final_builds/packages/fake-package-name',
            File.read(package_tarball),
            {
              'version' => 'fake-package-fingerprint',
            }
          )
        end

        let(:release_manifest) do
          original_release_manifest.merge(
            'packages' => [{
              'name' => 'fake-package-name',
              'sha1' => Digest::SHA1.file(package_tarball).hexdigest,
            }])
        end

        it 'copies packages' do
          release_compiler.compile
          expect(list_tar_files(release_tarball_file)).to include('./packages/fake-package-name.tgz')
        end
      end

      context 'when jobs exist' do
        before do
          release_source.add_version(
            'fake-job-fingerprint',
            '.final_builds/jobs/fake-job-name',
            File.read(job_tarball),
            {
              'version' => 'fake-job-fingerprint',
            }
          )
        end

        let(:release_manifest) do
          original_release_manifest.merge(
            'jobs' => [{
              'name' => 'fake-job-name',
              'sha1' => Digest::SHA1.file(job_tarball).hexdigest,
            }])
        end

        it 'copies jobs' do
          release_compiler.compile
          expect(list_tar_files(release_tarball_file)).to include('./jobs/fake-job-name.tgz')
        end
      end

      context 'when license exists' do
        before do
          release_source.add_version(
            'fake-license-fingerprint',
            '.final_builds/license',
            File.read(license_tarball.path),
            {
              'version' => 'fake-license-fingerprint',
            }
          )
        end

        let(:release_manifest) do
          original_release_manifest.merge(
            'license' => {
              'sha1' => Digest::SHA1.file(license_tarball.path).hexdigest,
            })
        end

        it 'copies license' do
          release_compiler.compile
          expect(list_tar_files(release_tarball_file)).to include('./LICENSE')
          expect(list_tar_files(release_tarball_file)).to include('./NOTICE')
          expect(list_tar_files(release_tarball_file)).to_not include('./license.tgz')
        end
      end
    end
  end
end
