require 'rails_helper'

RSpec.describe 'TimeReports API' do
  let(:admin_user) { create :admin }
  let(:team) { create :team }
  let(:project) { create :project, team: team }
  let(:user) { create :user, team: team }
  let(:headers) { auth_headers(admin_user) }

  let!(:time_entry_1) { create(:time_entry, details: 'first', project_id: project.id, user_id: user.id) }
  let!(:time_entry_2) { create(:time_entry, details: 'second', project_id: project.id, user_id: user.id) }

  describe 'GET /time_reports/' do
    it 'should generate time report' do
      get '/api/v1/reports/time_reports', headers: headers

      expect(json['data'].count).to eq 2
      expect(json['data'].first['project']['id']).to eq time_entry_1.project.id
    end
  end

end