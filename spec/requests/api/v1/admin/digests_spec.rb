# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Admin::Digests', type: :request do
  let(:admin) { create(:user, :admin, email: "admin-#{SecureRandom.hex(6)}@example.com") }
  let(:moderator) { create(:user, :moderator, email: "mod-#{SecureRandom.hex(6)}@example.com") }

  def token_for(user)
    Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
  end

  describe 'POST /api/v1/admin/digest' do
    it 'returns 403 for non-admin' do
      post api_v1_admin_digest_path, headers: { 'Authorization' => "Bearer #{token_for(moderator)}" }
      expect(response).to have_http_status(:forbidden)
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it 'sends the digest to all admins' do
      other_admin = create(:user, :admin, email: "other-#{SecureRandom.hex(6)}@example.com")
      post api_v1_admin_digest_path, headers: { 'Authorization' => "Bearer #{token_for(admin)}" }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['sent']).to eq(2)
      expect(json['recipients']).to contain_exactly(admin.email, other_admin.email)
      expect(json['counts']).to include(
        'birthdays' => a_kind_of(Integer),
        'new_people' => a_kind_of(Integer),
        'photos' => a_kind_of(Integer)
      )
      expect(ActionMailer::Base.deliveries.size).to eq(2)
    end
  end
end
