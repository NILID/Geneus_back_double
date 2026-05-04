# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Auth::Invitations', type: :request do
  let(:inviter) { create(:user) }

  def bearer_token_for(user)
    Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
  end

  describe 'POST /api/v1/auth/invitations/link' do
    it 'returns 401 without token' do
      post '/api/v1/auth/invitations/link',
           params: { user: { email: 'guest@example.com' } },
           as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'creates invite without email and returns url and share text' do
      before_mails = ActionMailer::Base.deliveries.size
      expect do
        post '/api/v1/auth/invitations/link',
             params: { user: { email: 'manual_invite@example.com' } },
             headers: { 'Authorization' => "Bearer #{bearer_token_for(inviter)}" },
             as: :json
      end.to change(User, :count).by(1)

      expect(ActionMailer::Base.deliveries.size).to eq(before_mails)
      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['email']).to eq('manual_invite@example.com')
      expect(json['invitation_url']).to include('invitation_token=')
      expect(json['invitation_text']).to include(json['invitation_url'])
      expect(json['invitation_expires_at']).to be_present
      expires = Time.zone.parse(json['invitation_expires_at'])
      expect(expires).to be > Time.current
      expect(expires).to be_within(1.minute).of(24.hours.from_now)

      invited = User.find_by!(email: 'manual_invite@example.com')
      expect(invited.invited_by).to eq(inviter)
      expect(invited.invitation_sent_at).to be_present
    end
  end

  describe 'POST /api/v1/auth/invitations' do
    it 'returns 401 without token' do
      post '/api/v1/auth/invitations',
           params: { user: { email: 'guest@example.com' } },
           as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'creates an invited user and returns 201' do
      expect do
        post '/api/v1/auth/invitations',
             params: { user: { email: 'invited_user@example.com' } },
             headers: { 'Authorization' => "Bearer #{bearer_token_for(inviter)}" },
             as: :json
      end.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['email']).to eq('invited_user@example.com')

      invited = User.find_by!(email: 'invited_user@example.com')
      expect(invited.invited_by).to eq(inviter)
      expect(invited.invitation_token).to be_present
    end

    it 'returns 422 when email is already taken' do
      existing = create(:user, email: 'already_taken@example.com')
      post '/api/v1/auth/invitations',
           params: { user: { email: existing.email } },
           headers: { 'Authorization' => "Bearer #{bearer_token_for(inviter)}" },
           as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['errors']).to be_an(Array)
    end
  end

  describe 'PATCH /api/v1/auth/invitations' do
    let(:invitee) { User.invite!({ email: 'accept_me@example.com' }, inviter) }
    let(:raw_token) { invitee.raw_invitation_token }

    it 'accepts invitation, sets password, and returns JWT' do
      patch '/api/v1/auth/invitations',
            params: {
              user: {
                invitation_token: raw_token,
                password: 'Password1!',
                password_confirmation: 'Password1!'
              }
            },
            as: :json

      expect(response).to have_http_status(:ok)
      expect(response.headers['Authorization']).to be_present
      json = JSON.parse(response.body)
      expect(json['email']).to eq('accept_me@example.com')

      u = User.find_by!(email: 'accept_me@example.com')
      expect(u.invitation_accepted_at).to be_present
      expect(u.valid_password?('Password1!')).to be(true)
    end

    it 'returns 422 for wrong token' do
      patch '/api/v1/auth/invitations',
            params: {
              user: {
                invitation_token: 'invalid-token',
                password: 'Password1!',
                password_confirmation: 'Password1!'
              }
            },
            as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
