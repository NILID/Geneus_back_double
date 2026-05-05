# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Audits', type: :request do
  let(:user) { create(:user, :admin) }
  let!(:person) do
    create(:person, first_name: 'Audit', last_name: 'Target', gender: 'male', chart_id: 'audit-person-1')
  end

  def bearer_token
    Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
  end

  def auth_headers
    { 'Authorization' => "Bearer #{bearer_token}" }
  end

  describe 'GET /api/v1/audits' do
    it 'returns 401 without token' do
      get api_v1_audits_path
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns audits after an authenticated update' do
      patch api_v1_person_path(person.id),
            params: { person: { first_name: 'Renamed', last_name: person.last_name, gender: person.gender } },
            headers: auth_headers,
            as: :json

      expect(response).to have_http_status(:ok)

      get api_v1_audits_path, headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['audits']).to be_an(Array)
      expect(json['meta']).to include('page', 'per_page', 'total_count', 'total_pages')

      person_audit = json['audits'].find { |a| a['auditable_type'] == 'Person' && a['auditable_id'] == person.id }
      expect(person_audit).to be_present
      expect(person_audit['action']).to eq('update')
      expect(person_audit['user_id']).to eq(user.id)
      expect(person_audit['user_email']).to eq(user.email)
    end

    it 'filters by action_type' do
      patch api_v1_person_path(person.id),
            params: { person: { first_name: 'X', last_name: person.last_name, gender: person.gender } },
            headers: auth_headers,
            as: :json

      get api_v1_audits_path, params: { action_type: 'update' }, headers: auth_headers
      json = JSON.parse(response.body)
      expect(json['audits'].any? { |a| a['auditable_id'] == person.id }).to be true
      expect(json['audits'].all? { |a| a['action'] == 'update' }).to be true
    end
  end

  describe 'GET /api/v1/audits/filter_options' do
    it 'returns 401 without token' do
      get '/api/v1/audits/filter_options'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns filter metadata' do
      get '/api/v1/audits/filter_options', headers: auth_headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['actions']).to eq(%w[create update destroy])
      expect(json['auditable_types']).to be_an(Array)
      expect(json['users']).to be_an(Array)
    end
  end
end
