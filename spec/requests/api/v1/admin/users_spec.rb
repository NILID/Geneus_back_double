# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Admin::Users', type: :request do
  let(:admin) { create(:user, :admin, email: "admin-#{SecureRandom.hex(6)}@example.com") }
  let(:other) { create(:user, :moderator, email: "mod-#{SecureRandom.hex(6)}@example.com") }

  def token_for(user)
    Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
  end

  describe 'GET /api/v1/admin/users' do
    it 'returns 403 for non-admin' do
      get api_v1_admin_users_path, headers: { 'Authorization' => "Bearer #{token_for(other)}" }
      expect(response).to have_http_status(:forbidden)
    end

    it 'returns users for admin' do
      admin
      other
      get api_v1_admin_users_path, headers: { 'Authorization' => "Bearer #{token_for(admin)}" }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['users']).to be_an(Array)
      emails = json['users'].map { |u| u['email'] }
      expect(emails).to include(admin.email, other.email)
    end
  end

  describe 'PATCH /api/v1/admin/users/:id' do
    it 'returns 403 for non-admin' do
      patch api_v1_admin_user_path(other.id),
            params: { user: { role: 'user' } },
            headers: { 'Authorization' => "Bearer #{token_for(other)}" },
            as: :json
      expect(response).to have_http_status(:forbidden)
    end

    it 'updates role' do
      target = create(:user, email: "usr-#{SecureRandom.hex(6)}@example.com")
      patch api_v1_admin_user_path(target.id),
            params: { user: { role: 'moderator' } },
            headers: { 'Authorization' => "Bearer #{token_for(admin)}" },
            as: :json
      expect(response).to have_http_status(:ok)
      expect(target.reload.role).to eq('moderator')
    end
  end
end
