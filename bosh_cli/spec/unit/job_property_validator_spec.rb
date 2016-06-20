# Copyright (c) 2009-2012 VMware, Inc.

require "spec_helper"

describe Bosh::Cli::JobPropertyValidator do
  before do
    allow(File).to receive(:read).with('/jobs/director/templates/director.yml.erb.erb').and_return('---\nname: <%= p("director.name") %>')
    allow(File).to receive(:read).with('/jobs/blobstore/templates/blobstore.yml.erb').and_return('---\nprovider: <%= p("blobstore.provider") %>')
    allow(File).to receive(:read).with('/jobs/blobstore/templates/test.yml.erb').and_return('---\nhost: <%= spec.networks.send("foo").ip %>')
  end

  let(:director_job) do
    instance_double(Bosh::Cli::Resources::Job,
           name: 'director',
           properties: {'director.name' =>
                            {'description' => 'Name of director'},
                        'director.port' =>
                            {'description' => 'Port that the director nginx listens on', 'default' => 25555}},
          files: [['/jobs/director/templates/director.yml.erb.erb', :whatever]])
  end

  let(:blobstore_job) do
    instance_double(Bosh::Cli::Resources::Job,
           name: 'blobstore',
           properties: {'blobstore.provider' =>
                            {'description' => 'Type of blobstore'}},
           files: [['/jobs/blobstore/templates/blobstore.yml.erb', :whatever], ['/jobs/blobstore/templates/test.yml.erb', :whatever]])
  end

  let(:built_jobs) { [director_job, blobstore_job] }

  let(:deployment_manifest) do
    {
        'properties' => deployment_properties,
        'networks' => [{
          'subnets' => [{
            'reserved' => [
            ],
          }]
        }],
        'jobs' => [{
          'name' => 'bosh',
          'template' => job_template_list,
          'networks' => [
            'name' => 'foo',
          ]
        }]
    }
  end

  subject(:validator) { described_class.new(built_jobs, deployment_manifest) }

  context 'missing deployment manifest properties' do
    let(:deployment_properties) { {} }

    context 'colocated jobs' do
      let(:job_template_list) { %w[director blobstore] }

      it 'should have template errors' do
        validator.validate

        expect(validator.template_errors.size).to eq(2)
        expect(validator.template_errors.first.exception.to_s).to eq "Can't find property '[\"director.name\"]'"
        expect(validator.template_errors.last.exception.to_s).to eq "Can't find property '[\"blobstore.provider\"]'"
      end
    end

    context 'non-colocated jobs' do
      let(:job_template_list) { 'director' }

      it 'should have template errors' do
        validator.validate

        expect(validator.template_errors.size).to eq(1)
        expect(validator.template_errors.first.exception.to_s).to eq "Can't find property '[\"director.name\"]'"
      end
    end
  end

  context 'all deployment manifest properties defined' do
    let(:deployment_properties) do
      {
          'director'  => {'name' => 'foo'},
          'blobstore' => {'provider' => 's3'}
      }
    end

    let(:job_template_list) { %w[director blobstore] }

    it 'should not have template errors' do

      expect(validator.template_errors).to be_empty
    end

    context 'with index' do
      before do
      end

      it 'should not have template errors' do

        expect(validator.template_errors).to be_empty
      end
    end
  end

  context 'legacy job template with no properties' do
    let(:no_props_job) do
      instance_double(Bosh::Cli::Resources::Job,
             name: 'noprops',
             properties: {},
             files: [])
    end

    let(:built_jobs) { [director_job, no_props_job] }

    let(:job_template_list) { %w[director noprops] }

    let(:deployment_properties) { {} }

    it 'should identify legacy jobs with no properties' do

      expect(validator.jobs_without_properties.size).to eq(1)
      expect(validator.jobs_without_properties.first.name).to eq 'noprops'
    end
  end
end
