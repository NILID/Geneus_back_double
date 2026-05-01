# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::GalleryPhotos', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let!(:tag_person) { create(:person, first_name: 'Tagged', last_name: 'One', gender: 'female') }

  def bearer_token(for_user = user)
    Warden::JWTAuth::UserEncoder.new.call(for_user, :user, nil).first
  end

  describe 'GET /api/v1/gallery_photos' do
    it 'returns 401 without token' do
      get api_v1_gallery_photos_path
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns all users photos with image_url and uploader' do
      mine = create(:gallery_photo, user: user, caption: 'A')
      theirs = create(:gallery_photo, user: other_user, caption: 'B')
      get api_v1_gallery_photos_path, headers: { 'Authorization' => "Bearer #{bearer_token}" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      ids = json['gallery_photos'].map { |h| h['id'] }
      expect(ids).to contain_exactly(mine.id, theirs.id)
      mine_json = json['gallery_photos'].find { |h| h['id'] == mine.id }
      expect(mine_json['caption']).to eq('A')
      expect(mine_json['user_id']).to eq(user.id)
      expect(mine_json['uploaded_by_email']).to eq(user.email)
      expect(mine_json['image_url']).to be_present
      expect(mine_json['tagged_people']).to eq([])
    end
  end

  describe 'POST /api/v1/gallery_photos' do
    it 'returns 401 without token' do
      png = Rack::Test::UploadedFile.new(
        Rails.root.join('spec/fixtures/files/1x1.png'),
        'image/png'
      )
      post api_v1_gallery_photos_path, params: { gallery_photo: { image: png } }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'creates a photo with caption' do
      png = Rack::Test::UploadedFile.new(
        Rails.root.join('spec/fixtures/files/1x1.png'),
        'image/png'
      )
      expect do
        post api_v1_gallery_photos_path,
             params: { gallery_photo: { caption: 'Vacation', image: png } },
             headers: { 'Authorization' => "Bearer #{bearer_token}" }
      end.to change(GalleryPhoto, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['gallery_photo']['caption']).to eq('Vacation')
      expect(json['gallery_photo']['user_id']).to eq(user.id)
      expect(json['gallery_photo']['uploaded_by_email']).to eq(user.email)
      expect(json['gallery_photo']['image_url']).to be_present
    end

    it 'creates with person_ids' do
      png = Rack::Test::UploadedFile.new(
        Rails.root.join('spec/fixtures/files/1x1.png'),
        'image/png'
      )
      post api_v1_gallery_photos_path,
           params: { gallery_photo: { caption: 'With tags', image: png, person_ids: [tag_person.id] } },
           headers: { 'Authorization' => "Bearer #{bearer_token}" }

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['gallery_photo']['tagged_people'].length).to eq(1)
      expect(json['gallery_photo']['tagged_people'][0]['id']).to eq(tag_person.id)
      expect(GalleryPhoto.last.tagged_people).to include(tag_person)
    end

    it 'returns 422 without file' do
      post api_v1_gallery_photos_path,
           params: { gallery_photo: { caption: 'Only text' } },
           headers: { 'Authorization' => "Bearer #{bearer_token}" },
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'PATCH /api/v1/gallery_photos/:id' do
    it 'returns 401 without token' do
      photo = create(:gallery_photo, user: user)
      patch api_v1_gallery_photo_path(photo), params: { gallery_photo: { caption: 'X' } }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'updates caption for own photo' do
      photo = create(:gallery_photo, user: user, caption: 'Old')
      patch api_v1_gallery_photo_path(photo),
            params: { gallery_photo: { caption: 'New title' } },
            headers: { 'Authorization' => "Bearer #{bearer_token}" },
            as: :json

      expect(response).to have_http_status(:ok)
      expect(photo.reload.caption).to eq('New title')
      json = JSON.parse(response.body)
      expect(json['gallery_photo']['caption']).to eq('New title')
    end

    it 'clears caption when sent blank' do
      photo = create(:gallery_photo, user: user, caption: 'Old')
      patch api_v1_gallery_photo_path(photo),
            params: { gallery_photo: { caption: '' } },
            headers: { 'Authorization' => "Bearer #{bearer_token}" },
            as: :json

      expect(response).to have_http_status(:ok)
      expect(photo.reload.caption).to be_nil
    end

    it 'returns 404 when updating other user photo' do
      photo = create(:gallery_photo, user: other_user)
      patch api_v1_gallery_photo_path(photo),
            params: { gallery_photo: { caption: 'Hack' } },
            headers: { 'Authorization' => "Bearer #{bearer_token}" },
            as: :json

      expect(response).to have_http_status(:not_found)
    end

    it 'replaces image for own photo' do
      photo = create(:gallery_photo, user: user)
      png = Rack::Test::UploadedFile.new(
        Rails.root.join('spec/fixtures/files/1x1.png'),
        'image/png'
      )
      patch api_v1_gallery_photo_path(photo),
            params: { gallery_photo: { image: png } },
            headers: { 'Authorization' => "Bearer #{bearer_token}" }

      expect(response).to have_http_status(:ok)
      expect(photo.reload.image).to be_attached
    end

    it 'updates person_ids for own photo' do
      photo = create(:gallery_photo, user: user)
      patch api_v1_gallery_photo_path(photo),
            params: { gallery_photo: { person_ids: [tag_person.id] } },
            headers: { 'Authorization' => "Bearer #{bearer_token}" },
            as: :json

      expect(response).to have_http_status(:ok)
      expect(photo.reload.tagged_people).to contain_exactly(tag_person)
      json = JSON.parse(response.body)
      expect(json['gallery_photo']['tagged_people'].map { |h| h['id'] }).to eq([tag_person.id])
    end
  end
    it 'returns 401 without token' do
      photo = create(:gallery_photo, user: user)
      delete api_v1_gallery_photo_path(photo)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'deletes own photo' do
      photo = create(:gallery_photo, user: user)
      expect do
        delete api_v1_gallery_photo_path(photo),
               headers: { 'Authorization' => "Bearer #{bearer_token}" }
      end.to change(GalleryPhoto, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end

    it 'returns 404 for other user photo' do
      photo = create(:gallery_photo, user: other_user)
      delete api_v1_gallery_photo_path(photo),
             headers: { 'Authorization' => "Bearer #{bearer_token}" }
      expect(response).to have_http_status(:not_found)
    end
  end
end
