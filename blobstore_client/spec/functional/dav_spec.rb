require 'spec_helper'

describe Bosh::Blobstore::DavBlobstoreClient, nginx: true do
  def create_user_file(users)
  end

  def create_test_blob
    File.open(path, 'w') do |f|
    end

  end

  class NginxConfig < Struct.new(:port, :root, :read_users_path, :write_users_path)
    def render
    end
  end

  before(:all) do






  end

  after(:all) do
  end

  before(:each) do
  end

  after(:each) do
  end



  context 'read users' do

    context 'with authorized user' do

      it 'allows read' do
        expect(subject.get('test')).to eq 'test'
      end

      it 'allows checking for existance' do
        expect(subject.exists?('test')).to be(true)
      end
    end

    context 'with unauthorized user' do

      it "doesn't allow read" do
        expect { subject.get('test') }.to raise_error(Bosh::Blobstore::BlobstoreError, /Could not fetch object, 401/)
      end

      it 'does not allow checking for existance' do
        expect { subject.exists?('test') }.to raise_error(Bosh::Blobstore::BlobstoreError, /Could not get object existence, 401/)
      end
    end

  end

  context 'write users' do
    context 'with authorized user' do

      it 'allows write' do
        expect { subject.create('foo') }.to_not raise_error
      end

      it 'allows delete' do
        expect { subject.delete('test') }.to_not raise_error
      end

     it 'should raise NotFound error when deleting non-existing file' do
       expect { subject.delete('non-exist-file') }.to raise_error Bosh::Blobstore::NotFound, /Object 'non-exist-file' is not found/
     end

      it 'allows checking for existance' do
        expect(subject.exists?('test')).to be(true)
      end
    end

    context 'with unauthorized user' do

      it "doesn't allow write" do
        expect { subject.create('foo', 'test') }.to raise_error(Bosh::Blobstore::BlobstoreError, /Could not create object, 401/)
      end

      it "doesn't allow delete" do
        expect { subject.delete('test') }.to raise_error(Bosh::Blobstore::BlobstoreError, /Could not delete object, 401/)
      end

      it 'does not allow checking for existance' do
        expect { subject.exists?('test') }.to raise_error(Bosh::Blobstore::BlobstoreError, /Could not get object existence, 401/)
      end
    end

    context 'with read only user' do

      it "doesn't allow write" do
        expect { subject.create('foo', 'test') }.to raise_error(Bosh::Blobstore::BlobstoreError, /Could not create object, 401/)
      end

      it "doesn't allow delete" do
        expect { subject.delete('test') }.to raise_error(Bosh::Blobstore::BlobstoreError, /Could not delete object, 401/)
      end
    end
  end
end
