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

  describe 'DELETE /api/v1/ideas/:id' do
    let(:idea) { create(:idea, user: other_user, body: 'Идея на удаление') }

    it 'returns 401 without token' do
      delete api_v1_idea_path(idea)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 403 for a plain user' do
      create(:comment, commentable: idea, user: user, body: 'Комментарий')
      expect do
        delete api_v1_idea_path(idea),
               headers: { 'Authorization' => "Bearer #{bearer_token}" }
      end.not_to change(Idea, :count)

      expect(response).to have_http_status(:forbidden)
      expect(idea.reload.comments.count).to eq(1)
    end

    it 'returns 403 for a moderator' do
      moderator = create(:user, :moderator)
      delete api_v1_idea_path(idea),
             headers: { 'Authorization' => "Bearer #{bearer_token(moderator)}" }

      expect(response).to have_http_status(:forbidden)
    end

    it 'deletes the idea and its comments for an admin' do
      admin = create(:user, :admin)
      create(:comment, commentable: idea, user: user, body: 'Комментарий')

      expect do
        delete api_v1_idea_path(idea),
               headers: { 'Authorization' => "Bearer #{bearer_token(admin)}" }
      end.to change(Idea, :count).by(-1).and change(Comment, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it 'returns 404 for a missing idea' do
      admin = create(:user, :admin)
      delete api_v1_idea_path(0),
             headers: { 'Authorization' => "Bearer #{bearer_token(admin)}" }

      expect(response).to have_http_status(:not_found)
    end
  end
end
