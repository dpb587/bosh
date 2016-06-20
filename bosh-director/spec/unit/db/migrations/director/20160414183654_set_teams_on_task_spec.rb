require 'db_spec_helper'

module Bosh::Director
  describe 'set_teams_on_task' do
    let(:db) { DBSpecHelper.db }
    let(:migration_file) { '20160414183654_set_teams_on_task.rb' }

    before { DBSpecHelper.migrate_all_before(migration_file) }

    it 'allows teams to optionally be added to tasks' do
      db[:tasks] << {
          state: 'finished',
          type: 'something',
          timestamp: '2016-04-14 11:53:42',
          description: 'delete_deployment',
      }

      DBSpecHelper.migrate(migration_file)

      db[:tasks] << {
          state: 'finished',
          type: 'something',
          timestamp: '2016-04-14 11:53:42',
          description: 'delete_deployment',
          teams: 'dev,qa',
      }

      db[:tasks] << {
          state: 'finished',
          type: 'something',
          timestamp: '2016-04-14 11:53:42',
          description: 'delete_deployment',
      }

      tasks = db[:tasks].all
      expect(tasks.count).to eq(3)
      expect(tasks[0][:teams]).to be_nil
      expect(tasks[1][:teams]).to eq('dev,qa')
      expect(tasks[2][:teams]).to be_nil
    end
  end
end
