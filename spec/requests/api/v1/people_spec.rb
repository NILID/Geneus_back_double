# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::People', type: :request do
  let(:user) { create(:user) }
  let!(:person) { create(:person, name: 'Api Person', gender: 'male', chart_id: 'chart-xyz') }

  def bearer_token
    Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
  end

  describe 'GET /api/v1/people/:id' do
    it 'returns 401 without token' do
      get api_v1_person_path(person.id)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'resolves by numeric id' do
      get api_v1_person_path(person.id), headers: { 'Authorization' => "Bearer #{bearer_token}" }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['person']['id']).to eq(person.id)
      expect(json['person']['name']).to eq('Api Person')
    end

    it 'resolves by chart_id when not all-digits' do
      get api_v1_person_path('chart-xyz'), headers: { 'Authorization' => "Bearer #{bearer_token}" }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['person']['chart_external_id']).to eq('chart-xyz')
    end

    it 'returns 404 for unknown id' do
      missing_id = (Person.maximum(:id) || 0) + 99_999
      get api_v1_person_path(missing_id), headers: { 'Authorization' => "Bearer #{bearer_token}" }
      expect(response).to have_http_status(:not_found)
    end
  end
end
