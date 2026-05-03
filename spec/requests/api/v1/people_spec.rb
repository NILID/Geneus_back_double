# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::People', type: :request do
  let(:user) { create(:user) }
  let!(:person) do
    create(:person, first_name: 'Api', last_name: 'Person', gender: 'male', chart_id: 'chart-xyz')
  end

  def bearer_token
    Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first
  end

  describe 'GET /api/v1/people/:id' do
    it 'returns 401 without token' do
      get api_v1_person_path(person.id)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'resolves by numeric id' do
      get api_v1_person_path(person.id), headers: { 'Authorization' => "Bearer #{bearer_token}" }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['person']['id']).to eq(person.id)
      expect(json['person']['first_name']).to eq('Api')
      expect(json['person']['last_name']).to eq('Person')
      expect(json['person']['avatar_url']).to be_nil
    end

    it 'resolves by chart_id when not all-digits' do
      get api_v1_person_path('chart-xyz'), headers: { 'Authorization' => "Bearer #{bearer_token}" }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['person']['chart_external_id']).to eq('chart-xyz')
    end

    it 'returns 404 for unknown id' do
      missing_id = (Person.maximum(:id) || 0) + 99_999
      get api_v1_person_path(missing_id), headers: { 'Authorization' => "Bearer #{bearer_token}" }
      expect(response).to have_http_status(:not_found)
    end

    it 'includes birth and death coordinates when set' do
      person.update!(
        birth_latitude: 59.93428,
        birth_longitude: 30.335098,
        death_latitude: 55.755864,
        death_longitude: 37.617698
      )

      get api_v1_person_path(person.id), headers: { 'Authorization' => "Bearer #{bearer_token}" }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['person']['birth_latitude']).to eq(59.93428)
      expect(json['person']['birth_longitude']).to eq(30.335098)
      expect(json['person']['death_latitude']).to eq(55.755864)
      expect(json['person']['death_longitude']).to eq(37.617698)
    end

    it 'includes tagged_gallery_photos when person is tagged on media' do
      tagged = create(:person, first_name: 'On', last_name: 'Photo', gender: 'male')
      gp = create(:gallery_photo, user: user)
      gp.tagged_people = [tagged]

      get api_v1_person_path(tagged.id), headers: { 'Authorization' => "Bearer #{bearer_token}" }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      photos = json['person']['tagged_gallery_photos']
      expect(photos.length).to eq(1)
      expect(photos[0]['id']).to eq(gp.id)
      expect(photos[0]['image_url']).to be_present
    end
  end

  describe 'GET /api/v1/people/map_locations' do
    it 'returns 401 without token' do
      get map_locations_api_v1_people_path
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns people that have at least one coordinate pair' do
      person.update!(
        birth_latitude: 59.93,
        birth_longitude: 30.33,
        death_latitude: nil,
        death_longitude: nil
      )
      empty_geo = create(:person, first_name: 'No', last_name: 'Coords', gender: 'female')

      get map_locations_api_v1_people_path, headers: { 'Authorization' => "Bearer #{bearer_token}" }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      ids = json['people'].map { |p| p['id'] }
      expect(ids).to include(person.id)
      expect(ids).not_to include(empty_geo.id)
    end
  end

  describe 'PATCH /api/v1/people/:id' do
    it 'returns 401 without token' do
      patch api_v1_person_path(person.id), params: { person: { first_name: 'Updated' } }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'updates allowed fields and returns serialized person' do
      patch api_v1_person_path('chart-xyz'),
            params: {
              person: {
                first_name: 'Updated',
                last_name: 'Name',
                gender: 'male',
                bio: 'New bio',
                date_of_birth: '1990-05-15',
                date_of_death: '',
                location_of_birth: 'Moscow',
                location_of_death: nil
              }
            },
            headers: { 'Authorization' => "Bearer #{bearer_token}" },
            as: :json

      expect(response).to have_http_status(:ok)
      person.reload
      expect(person.first_name).to eq('Updated')
      expect(person.last_name).to eq('Name')
      expect(person.bio).to eq('New bio')
      expect(person.date_of_birth).to eq(Date.new(1990, 5, 15))
      expect(person.date_of_death).to be_nil
      expect(person.location_of_birth).to eq('Moscow')

      json = JSON.parse(response.body)
      expect(json['person']['first_name']).to eq('Updated')
      expect(json['person']['last_name']).to eq('Name')
    end

    it 'updates geographic coordinates via JSON' do
      patch api_v1_person_path(person.id),
            params: {
              person: {
                first_name: person.first_name,
                last_name: person.last_name,
                gender: person.gender,
                birth_latitude: 59.93428,
                birth_longitude: 30.335098,
                death_latitude: '',
                death_longitude: ''
              }
            },
            headers: { 'Authorization' => "Bearer #{bearer_token}" },
            as: :json

      expect(response).to have_http_status(:ok)
      person.reload
      expect(person.birth_latitude.to_f).to be_within(1e-5).of(59.93428)
      expect(person.birth_longitude.to_f).to be_within(1e-5).of(30.335098)
      expect(person.death_latitude).to be_nil
    end

    it 'returns 422 on validation error' do
      patch api_v1_person_path(person.id),
            params: { person: { first_name: '', gender: 'male' } },
            headers: { 'Authorization' => "Bearer #{bearer_token}" },
            as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json['errors']).to be_a(Array)
    end

    it 'returns 404 for unknown id' do
      missing_id = (Person.maximum(:id) || 0) + 99_999
      patch api_v1_person_path(missing_id),
            params: { person: { first_name: 'Nope' } },
            headers: { 'Authorization' => "Bearer #{bearer_token}" },
            as: :json
      expect(response).to have_http_status(:not_found)
    end

    it 'attaches avatar via multipart' do
      png = Rack::Test::UploadedFile.new(
        Rails.root.join('spec/fixtures/files/1x1.png'),
        'image/png'
      )
      patch api_v1_person_path(person.id),
            params: {
              person: {
                first_name: person.first_name,
                last_name: person.last_name,
                gender: person.gender,
                bio: person.bio,
                avatar: png
              }
            },
            headers: { 'Authorization' => "Bearer #{bearer_token}" }

      expect(response).to have_http_status(:ok)
      person.reload
      expect(person.avatar.attached?).to be true
      json = JSON.parse(response.body)
      expect(json['person']['avatar_url']).to be_present
    end
  end
end
