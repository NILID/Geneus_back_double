# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::People::Facts', type: :request do
  let(:user) { create(:user) }
  let(:other) { create(:user) }
  let!(:person) { create(:person, first_name: 'Fact', last_name: 'Subject', gender: 'female') }

  def bearer_token(u)
    Warden::JWTAuth::UserEncoder.new.call(u, :user, nil).first
  end

  describe 'GET /api/v1/people/:person_id/facts' do
    it 'returns 401 without token' do
      get api_v1_person_facts_path(person.id)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns all facts newest first' do
      old = create(:person_fact, person: person, user: user, body: 'Старый')
      old.update_columns(created_at: 2.days.ago)
      new = create(:person_fact, person: person, user: other, body: 'Новый')
      new.update_columns(created_at: 1.hour.ago)

      get api_v1_person_facts_path(person.id), headers: { 'Authorization' => "Bearer #{bearer_token(user)}" }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      ids = json['person_facts'].map { |h| h['id'] }
      expect(ids).to eq([new.id, old.id])
    end

    it 'resolves person by chart_id' do
      person.update!(chart_id: 'cid-facts')
      create(:person_fact, person: person, user: user)

      get api_v1_person_facts_path('cid-facts'), headers: { 'Authorization' => "Bearer #{bearer_token(user)}" }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['person_facts'].length).to eq(1)
    end

    it 'returns 404 for unknown person' do
      missing = (Person.maximum(:id) || 0) + 99_999
      get api_v1_person_facts_path(missing), headers: { 'Authorization' => "Bearer #{bearer_token(user)}" }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/people/:person_id/facts' do
    it 'returns 401 without token' do
      post api_v1_person_facts_path(person.id), params: { person_fact: { body: 'x' } }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'creates a fact' do
      expect do
        post api_v1_person_facts_path(person.id),
             params: { person_fact: { body: '  Новый факт  ' } },
             headers: { 'Authorization' => "Bearer #{bearer_token(user)}" },
             as: :json
      end.to change(PersonFact, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['person_fact']['body']).to eq('Новый факт')
      expect(json['person_fact']['user_id']).to eq(user.id)
      expect(json['person_fact']['author_email']).to eq(user.email)
    end

    it 'returns 422 on empty body' do
      post api_v1_person_facts_path(person.id),
           params: { person_fact: { body: '   ' } },
           headers: { 'Authorization' => "Bearer #{bearer_token(user)}" },
           as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
