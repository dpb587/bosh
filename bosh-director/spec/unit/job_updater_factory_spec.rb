require 'spec_helper'

describe Bosh::Director::JobUpdaterFactory do
  subject(:job_updater_factory) { described_class.new(cloud, logger) }

  let(:cloud) { instance_double(Bosh::Cloud) }

  describe '#new_job_updater' do
    it 'returns job updater' do
      deployment_plan = instance_double('Bosh::Director::DeploymentPlan::Planner')
      job = instance_double('Bosh::Director::DeploymentPlan::InstanceGroup')

      links_resolver = instance_double('Bosh::Director::DeploymentPlan')
      expect(Bosh::Director::DeploymentPlan::LinksResolver).to receive(:new).
        and_return(links_resolver)

      job_updater = instance_double('Bosh::Director::JobUpdater')
      expect(Bosh::Director::JobUpdater).to receive(:new).and_return(job_updater)

      expect(job_updater_factory.new_job_updater(deployment_plan, job)).to eq(job_updater)
    end
  end
end
