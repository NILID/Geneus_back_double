# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Auth::Passwords', type: :request do
  let!(:user) { create(:user, email: 'reset-me@example.com') }

  describe 'POST /api/v1/auth/password' do
    it 'sends reset instructions with a frontend reset link' do
      before_mails = ActionMailer::Base.deliveries.size

      post '/api/v1/auth/password',
           params: { user: { email: user.email } },
           as: :json

      expect(response).to have_http_status(:accepted)
      expect(ActionMailer::Base.deliveries.size).to eq(before_mails + 1)

      mail = ActionMailer::Base.deliveries.last
      frontend = ENV.fetch('FRONTEND_URL', 'http://localhost:3000').chomp('/')

      expect(mail.to).to eq([user.email])
      expect(mail.body.encoded).to include("#{frontend}/reset-password?reset_password_token=")
    end
  end

  describe 'PATCH /api/v1/auth/password' do
    let(:raw_token) { user.send(:set_reset_password_token) }

    it 'resets password with a valid token' do
      patch '/api/v1/auth/password',
            params: {
              user: {
                reset_password_token: raw_token,
                password: 'NewPass1!',
                password_confirmation: 'NewPass1!'
              }
            },
            as: :json

      expect(response).to have_http_status(:ok)
      expect(user.reload.valid_password?('NewPass1!')).to be(true)
    end

    it 'returns errors for an invalid token' do
      patch '/api/v1/auth/password',
            params: {
              user: {
                reset_password_token: 'invalid-token',
                password: 'NewPass1!',
                password_confirmation: 'NewPass1!'
              }
            },
            as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response['errors']).to be_present
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
