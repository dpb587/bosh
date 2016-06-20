require 'spec_helper'

module Bosh::Director::Models
  describe PersistentDisk do
    subject(:persistent_disk) { described_class.make }

    describe 'cloud_properties' do
      let(:disk_cloud_properties) do
        {
        }
      end

      it 'updates cloud_properties' do

        expect(persistent_disk.cloud_properties).to eq(disk_cloud_properties)
      end
    end
  end
end
