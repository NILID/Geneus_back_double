# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Users (session profile)', type: :request do
  let(:user) { create(:user) }
  let!(:person) { create(:person, first_name: 'Link', last_name: 'Test', gender: 'male') }

  def bearer_token
    Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
  end

  describe 'GET /api/v1/auth/me' do
    it 'returns 401 without token' do
      get api_v1_auth_me_path
      expect(response).to have_http_status(:unauthorized)
    end

    it 'includes person_id (nil by default)' do
      get api_v1_auth_me_path, headers: { 'Authorization' => "Bearer #{bearer_token}" }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['id']).to eq(user.id)
      expect(json['email']).to eq(user.email)
      expect(json['person_id']).to be_nil
      expect(json['role']).to eq('user')
    end

    it 'includes person_id when set' do
      user.update!(person: person)
      get api_v1_auth_me_path, headers: { 'Authorization' => "Bearer #{bearer_token}" }
      json = JSON.parse(response.body)
      expect(json['person_id']).to eq(person.id)
    end

    it 'records last_seen_at and throttles repeats within 10 minutes' do
      expect(user.last_seen_at).to be_nil

      get api_v1_auth_me_path, headers: { 'Authorization' => "Bearer #{bearer_token}" }
      expect(response).to have_http_status(:ok)
      first_seen = user.reload.last_seen_at
      expect(first_seen).to be_within(2.seconds).of(Time.current)

      get api_v1_auth_me_path, headers: { 'Authorization' => "Bearer #{bearer_token}" }
      expect(user.reload.last_seen_at).to eq(first_seen)

      travel 11.minutes do
        get api_v1_auth_me_path, headers: { 'Authorization' => "Bearer #{bearer_token}" }
        expect(user.reload.last_seen_at).to be > first_seen
      end
    end
  end

  describe 'PATCH /api/v1/auth/me' do
    it 'returns 401 without token' do
      patch api_v1_auth_me_path, params: { user: { person_id: person.id } }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'links person' do
      patch api_v1_auth_me_path,
            params: { user: { person_id: person.id } },
            headers: { 'Authorization' => "Bearer #{bearer_token}" },
            as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['person_id']).to eq(person.id)
      expect(user.reload.person_id).to eq(person.id)
    end

    it 'clears link with null' do
      user.update!(person: person)
      patch api_v1_auth_me_path,
            params: { user: { person_id: nil } },
            headers: { 'Authorization' => "Bearer #{bearer_token}" },
            as: :json
      expect(response).to have_http_status(:ok)
      expect(user.reload.person_id).to be_nil
    end

    it 'rejects unknown person id' do
      missing_id = (Person.maximum(:id) || 0) + 99_999
      patch api_v1_auth_me_path,
            params: { user: { person_id: missing_id } },
            headers: { 'Authorization' => "Bearer #{bearer_token}" },
            as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['errors']).to be_an(Array)
    end

    it 'allows linking the same person as another user' do
      other = create(:user)
      other.update!(person: person)
      patch api_v1_auth_me_path,
            params: { user: { person_id: person.id } },
            headers: { 'Authorization' => "Bearer #{bearer_token}" },
            as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['person_id']).to eq(person.id)
      expect(user.reload.person_id).to eq(person.id)
    end
  end
end
