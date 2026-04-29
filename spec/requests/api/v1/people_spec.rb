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

  describe 'PATCH /api/v1/people/:id' do
    it 'returns 401 without token' do
      patch api_v1_person_path(person.id), params: { person: { name: 'Updated' } }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'updates allowed fields and returns serialized person' do
      patch api_v1_person_path('chart-xyz'),
            params: {
              person: {
                name: 'Updated Name',
                gender: 'male',
                bio: 'New bio',
                date_of_birth: '1990-05-15',
                date_of_death: '',
                location_of_birth: 'Moscow',
                location_of_death: nil
              }
            },
            headers: { 'Authorization' => "Bearer #{bearer_token}" },
            as: :json

      expect(response).to have_http_status(:ok)
      person.reload
      expect(person.name).to eq('Updated Name')
      expect(person.bio).to eq('New bio')
      expect(person.date_of_birth).to eq(Date.new(1990, 5, 15))
      expect(person.date_of_death).to be_nil
      expect(person.location_of_birth).to eq('Moscow')

      json = JSON.parse(response.body)
      expect(json['person']['name']).to eq('Updated Name')
    end

    it 'returns 422 on validation error' do
      patch api_v1_person_path(person.id),
            params: { person: { name: '', gender: 'male' } },
            headers: { 'Authorization' => "Bearer #{bearer_token}" },
            as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['errors']).to be_a(Array)
    end

    it 'returns 404 for unknown id' do
      missing_id = (Person.maximum(:id) || 0) + 99_999
      patch api_v1_person_path(missing_id),
            params: { person: { name: 'Nope' } },
            headers: { 'Authorization' => "Bearer #{bearer_token}" },
            as: :json
      expect(response).to have_http_status(:not_found)
    end
  end
end
