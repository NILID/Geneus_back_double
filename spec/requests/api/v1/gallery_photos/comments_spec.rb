# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::GalleryPhotos::Comments', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:owner) { create(:user) }
  let(:photo) { create(:gallery_photo, user: owner, caption: 'Shot') }

  def bearer_token(for_user = user)
    Warden::JWTAuth::UserEncoder.new.call(for_user, :user, nil).first
  end

  describe 'GET /api/v1/gallery_photos/:gallery_photo_id/comments' do
    it 'returns 401 without token' do
      get api_v1_gallery_photo_comments_path(photo)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns comments oldest first' do
      travel_to Time.zone.parse('2022-01-01') do
        create(:comment, commentable: photo, user: user, body: 'A')
      end
      travel_to Time.zone.parse('2022-01-02') do
        create(:comment, commentable: photo, user: owner, body: 'B')
      end

      get api_v1_gallery_photo_comments_path(photo), headers: { 'Authorization' => "Bearer #{bearer_token}" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['comments'].map { |h| h['body'] }).to eq(%w[A B])
    end
  end

  describe 'POST /api/v1/gallery_photos/:gallery_photo_id/comments' do
    it 'creates comment and increments counter' do
      expect do
        post api_v1_gallery_photo_comments_path(photo),
             params: { comment: { body: 'Класс' } },
             headers: { 'Authorization' => "Bearer #{bearer_token}" }
      end.to change(Comment, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['comment']['body']).to eq('Класс')
      expect(json['comments_count']).to eq(1)
      expect(photo.reload.comments_count).to eq(1)
    end
  end
end
