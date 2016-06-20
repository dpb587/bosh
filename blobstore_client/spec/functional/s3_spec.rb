require 'spec_helper'

module Bosh::Blobstore

  describe S3BlobstoreClient do
    let(:access_key_id) do
    end

    let(:secret_access_key) do
    end

    let(:s3_host) do
    end

    let(:bucket_name) do
    end

    context 'External Endpoint', aws_s3: true do
      let(:s3_options) do
        {
        }
      end

      let(:s3) do
      end

      after(:each) do
      end

      describe 'get object' do
        it 'should save to a file' do
          expect(file.read).to eq 'foobar'
        end

        it 'should save a file using v2 signature version' do
          expect(file.read).to eq 'foobar'
        end

        it 'should save a file using v4 signature version' do
          expect(file.read).to eq 'foobar'
        end
      end
    end

    context 'External Frankfurt Endpoint', aws_frankfurt_s3: true do
      let(:bucket_name) do
      end

      let(:s3_options) do
        {
        }
      end

      let(:s3) do
      end

      after(:each) do
      end

      describe 'get object' do
        it 'should save to a file' do
          expect(file.read).to eq 'foobar'
        end

        context 'when forcing the signature_version to v2' do
          it 'should not be able to save a file' do
            expect {
            }.to raise_error(/The authorization mechanism you have provided is not supported/)
          end
        end
      end
    end

    context 'Frankfurt Region', aws_frankfurt_s3: true do
      let(:bucket_name) do
      end

      let(:s3_options) do
        {
        }
      end

      let(:s3) do
      end

      after(:each) do
      end

      describe 'get object' do
        it 'should save to a file' do
          expect(file.read).to eq 'foobar'
        end
      end
    end

    context 'General S3', general_s3: true do
      context 'with force_path_style=true' do
        let(:s3_options) do
          {
          }
        end

        let(:s3) do
        end

        after(:each) do
        end

        describe 'get object' do
          it 'should save to a file' do
            expect(file.read).to eq 'foobar'
          end
        end

      end

      context 'Read/Write' do
        let(:s3_options) do
          {
          }
        end

        let(:s3) do
        end

        after(:each) do
        end

        describe 'unencrypted' do
          describe 'store object' do
            it 'should upload a file' do
              Tempfile.open('foo') do |file|
                expect(@oid).to_not be_nil
              end
            end

            it 'should upload a string' do
              expect(@oid).to_not be_nil
            end

            it 'should handle uploading the same object twice' do
              expect(@oid).to_not be_nil
              expect(@oid2).to_not be_nil
              expect(@oid).to_not eq @oid2
            end
          end

          describe 'get object' do
            it 'should save to a file' do
              expect(file.read).to eq 'foobar'
            end

            it 'should return the contents' do

              expect(s3.get(@oid)).to eq 'foobar'
            end

            it 'should raise an error when the object is missing' do

              expect { s3.get(id) }.to raise_error BlobstoreError, "S3 object '#{id}' not found"
            end
          end

          describe 'delete object' do
            it 'should delete an object' do

              expect { s3.delete(@oid) }.to_not raise_error

            end

            it "should raise an error when object doesn't exist" do
              expect { s3.delete('foobar') }.to raise_error Bosh::Blobstore::NotFound, /Object 'foobar' is not found/
            end
          end

          describe 'object exists?' do
            it 'should exist after create' do
              expect(s3.exists?(@oid)).to be true
            end

            it 'should return false if object does not exist' do
              expect(s3.exists?('foobar-fake')).to be false
            end
          end

        end
      end
    end

    # TODO: Make simple blobstore work with s3-compatible services
    context 'Read-Only', aws_s3: true do
      let(:s3_options) do
      end

      let(:s3) do
      end

      let(:contents) do
      end

      describe 'get object' do
        it 'should save to a file' do
          expect(file.read).to eq contents
        end

        it 'should return the contents' do
          expect(s3.get('public')).to eq contents
        end

        it 'should raise an error when the object is missing' do
          expect { s3.get('foooooo') }.to raise_error BlobstoreError, /Could not fetch object/
        end
      end

      describe 'create object' do
        it 'should raise an error' do
          expect { s3.create(contents) }.to raise_error BlobstoreError, 'unsupported action'
        end
      end

      describe 'delete object' do
        it 'should raise an error' do
          expect { s3.delete('public') }.to raise_error BlobstoreError, 'unsupported action'
        end
      end

      describe 'object exists?' do
        it 'the object should exist' do
          expect(s3.exists?('public')).to be true
        end
      end

    end
  end
end
