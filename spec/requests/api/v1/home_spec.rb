# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Home', type: :request do
  let(:user) { create(:user) }
  let!(:person) { create(:person, first_name: 'Stats', gender: 'male') }

  def bearer_token
    Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
  end

  describe 'GET /api/v1/home/stats' do
    it 'returns 401 without token' do
      get api_v1_home_stats_path
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns people and gallery photo counts' do
      create(:person, first_name: 'Other', gender: 'female')
      create(:gallery_photo, user: user)

      get api_v1_home_stats_path, headers: { 'Authorization' => "Bearer #{bearer_token}" }

      expect(response).to have_http_status(:ok)
      stats = JSON.parse(response.body)['stats']
      expect(stats.keys).to contain_exactly('people_count', 'gallery_photos_count')
      expect(stats['people_count']).to eq(2)
      expect(stats['gallery_photos_count']).to eq(1)
    end
  end
end
