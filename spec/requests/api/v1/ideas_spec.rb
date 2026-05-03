# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Ideas', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  def bearer_token(for_user = user)
    Warden::JWTAuth::UserEncoder.new.call(for_user, :user, nil).first
  end

  describe 'GET /api/v1/ideas' do
    it 'returns 401 without token' do
      get api_v1_ideas_path
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns ideas newest first' do
      travel_to Time.zone.parse('2020-01-01 10:00') do
        create(:idea, user: user, body: 'Старая идея')
      end
      newer = travel_to Time.zone.parse('2020-02-01 10:00') do
        create(:idea, user: other_user, body: 'Новая идея')
      end
      create(:comment, commentable: newer, user: user, body: 'Комментарий')

      get api_v1_ideas_path, headers: { 'Authorization' => "Bearer #{bearer_token}" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      ids = json['ideas'].map { |h| h['id'] }
      expect(ids.first).to eq(newer.id)

      first = json['ideas'].first
      expect(first['body']).to eq('Новая идея')
      expect(first['comments_count']).to eq(1)
      expect(first['author_email']).to eq(other_user.email)
      expect(first['user_id']).to eq(other_user.id)
    end
  end

  describe 'POST /api/v1/ideas' do
    it 'returns 401 without token' do
      post api_v1_ideas_path, params: { idea: { body: 'B' } }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'creates an idea' do
      expect do
        post api_v1_ideas_path,
             params: { idea: { body: '  Подробности предложения  ' } },
             headers: { 'Authorization' => "Bearer #{bearer_token}" }
      end.to change(Idea, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['idea']['body']).to eq('Подробности предложения')
      expect(json['idea']['user_id']).to eq(user.id)
      expect(json['idea']['author_email']).to eq(user.email)
      expect(json['idea']['comments_count']).to eq(0)
    end

    it 'returns 422 for empty body' do
      post api_v1_ideas_path,
           params: { idea: { body: '   ' } },
           headers: { 'Authorization' => "Bearer #{bearer_token}" }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
