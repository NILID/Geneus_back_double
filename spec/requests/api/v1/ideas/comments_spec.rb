# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Ideas::Comments', type: :request do
  let(:user) { create(:user) }
  let(:author) { create(:user) }
  let(:idea) { create(:idea, user: author, body: 'Предложение') }

  def bearer_token(for_user = user)
    Warden::JWTAuth::UserEncoder.new.call(for_user, :user, nil).first
  end

  describe 'GET /api/v1/ideas/:idea_id/comments' do
    it 'returns 401 without token' do
      get api_v1_idea_comments_path(idea)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns comments in chronological order' do
      travel_to Time.zone.parse('2021-01-01') do
        create(:comment, commentable: idea, user: user, body: 'Первый')
      end
      travel_to Time.zone.parse('2021-01-02') do
        create(:comment, commentable: idea, user: author, body: 'Второй')
      end

      get api_v1_idea_comments_path(idea), headers: { 'Authorization' => "Bearer #{bearer_token}" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      bodies = json['comments'].map { |h| h['body'] }
      expect(bodies).to eq(%w[Первый Второй])
    end
  end

  describe 'POST /api/v1/ideas/:idea_id/comments' do
    it 'returns 401 without token' do
      post api_v1_idea_comments_path(idea), params: { comment: { body: 'X' } }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'creates a comment and bumps comments_count' do
      expect do
        post api_v1_idea_comments_path(idea),
             params: { comment: { body: '  Отлично  ' } },
             headers: { 'Authorization' => "Bearer #{bearer_token}" }
      end.to change(Comment, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['comment']['body']).to eq('Отлично')
      expect(json['comment']['user_id']).to eq(user.id)
      expect(json['comments_count']).to eq(1)
      expect(idea.reload.comments_count).to eq(1)
    end

    it 'returns 404 for unknown idea' do
      post api_v1_idea_comments_path(0),
           params: { comment: { body: 'X' } },
           headers: { 'Authorization' => "Bearer #{bearer_token}" }

      expect(response).to have_http_status(:not_found)
    end
  end
end
