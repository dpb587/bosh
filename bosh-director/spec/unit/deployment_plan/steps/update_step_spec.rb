require 'spec_helper'

module Bosh::Director
  describe DeploymentPlan::Steps::UpdateStep do
    subject { DeploymentPlan::Steps::UpdateStep.new(base_job, deployment_plan, multi_job_updater, cloud) }
    let(:base_job) { Jobs::BaseJob.new }
    let(:ip_provider) {instance_double('Bosh::Director::DeploymentPlan::IpProvider')}
    let(:skip_drain) {instance_double('Bosh::Director::DeploymentPlan::SkipDrain')}

    let(:deployment_plan) do
      instance_double('Bosh::Director::DeploymentPlan::Planner',
        update_stemcell_references!: nil,
        instance_plans_with_missing_vms: [],
        ip_provider: ip_provider,
        recreate: false
      )
    end
    let(:cloud) { instance_double('Bosh::Cloud', delete_vm: nil) }
    let(:multi_job_updater) { instance_double('Bosh::Director::DeploymentPlan::SerialMultiJobUpdater', run: nil) }
    let(:task) {Bosh::Director::Models::Task.make(:id => 42, :username => 'user')}
    before do
      allow(Bosh::Director::Config).to receive(:cloud).and_return(cloud)
      allow(base_job).to receive(:task_id).and_return(task.id)
      allow(Bosh::Director::Config).to receive(:current_job).and_return(base_job)
      fake_app
    end

    describe '#perform' do
      let(:job1) { instance_double('Bosh::Director::DeploymentPlan::InstanceGroup', instances: [instance1, instance2]) }
      let(:job2) { instance_double('Bosh::Director::DeploymentPlan::InstanceGroup', instances: [instance3]) }
      let(:instance1) { instance_double('Bosh::Director::DeploymentPlan::Instance') }
      let(:instance2) { instance_double('Bosh::Director::DeploymentPlan::Instance') }
      let(:instance3) { instance_double('Bosh::Director::DeploymentPlan::Instance') }

      before do
      end

      def it_deletes_unneeded_instances
        existing_instance = Models::Instance.make
        allow(deployment_plan).to receive(:unneeded_instances).and_return([existing_instance])

        event_log_stage = instance_double('Bosh::Director::EventLog::Stage')
        expect(Config.event_log).to receive(:begin_stage)

        instance_deleter = instance_double('Bosh::Director::InstanceDeleter')
        expect(InstanceDeleter).to receive(:new)
                                     .and_return(instance_deleter)

        expect(instance_deleter).to receive(:delete_instance_plans) do |instance_plans, event_log, _|
          expect(instance_plans.map(&:existing_instance)).to eq([existing_instance])
        end
      end

      it 'runs deployment plan update stages in the correct order' do
        event_log_stage = instance_double('Bosh::Director::EventLog::Stage')
        allow(deployment_plan).to receive(:jobs_starting_on_deploy).with(no_args).and_return([job1, job2])

        it_deletes_unneeded_instances.ordered
        expect(base_job).to receive(:task_checkpoint).with(no_args).ordered
        expect(multi_job_updater).to receive(:run).with(base_job, deployment_plan, [job1, job2]).ordered
        expect(deployment_plan).to receive(:persist_updates!).ordered
        subject.perform
      end

      context 'when perform fails' do
        let(:some_error) { RuntimeError.new('oops') }

        before do
          existing_instance = Models::Instance.make(vm_cid: 'vm_cid')
          allow(deployment_plan).to receive(:unneeded_instances).and_return([existing_instance])
          agent_client = instance_double(AgentClient, drain: 0, stop: nil)
          allow(AgentClient).to receive(:with_vm_credentials_and_agent_id).and_return(agent_client)

          expect(cloud).to receive(:delete_vm).with('vm_cid').and_raise(some_error)
        end

        it 'still updates the stemcell references' do
          expect(deployment_plan).to receive(:update_stemcell_references!)

          expect{
            subject.perform
          }.to raise_error(some_error)
        end
      end
    end
  end
end
