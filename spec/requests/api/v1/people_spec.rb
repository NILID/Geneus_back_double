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
      expect(json['person']).to have_key('birth_date_year_only')
      expect(json['person']).to have_key('death_date_year_only')
      expect(json['person']['birth_date_year_only']).to be false
      expect(json['person']['death_date_year_only']).to be false
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
      expect(photos[0]['tagged_people']).to be_an(Array)
      expect(photos[0]['tagged_people'].map { |h| h['id'] }).to eq([tagged.id])
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

  describe 'GET /api/v1/people/recent' do
    it 'returns 401 without token' do
      get recent_api_v1_people_path
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns people ordered by updated_at descending' do
      person.update_column(:updated_at, 5.days.ago)
      older = create(:person, first_name: 'Older', gender: 'male')
      newer = create(:person, first_name: 'Newer', gender: 'female')
      older.update_column(:updated_at, 2.days.ago)
      newer.update_column(:updated_at, 1.day.ago)

      get recent_api_v1_people_path, headers: { 'Authorization' => "Bearer #{bearer_token}" }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      list = json['people']
      newer_idx = list.index { |p| p['first_name'] == 'Newer' }
      older_idx = list.index { |p| p['first_name'] == 'Older' }
      expect(newer_idx).not_to be_nil
      expect(older_idx).not_to be_nil
      expect(newer_idx).to be < older_idx
      first = list.first
      expect(first['id']).to eq(newer.id)
      expect(first['first_name']).to eq('Newer')
      expect(first['chart_external_id']).to be_a(String)
      expect(first['updated_at']).to be_present
    end
  end

  describe 'GET /api/v1/people/family_chart' do
    let!(:father) { create(:person, first_name: 'John', last_name: 'Doe', gender: 'male') }
    let!(:mother) { create(:person, first_name: 'Jane', last_name: 'Doe', gender: 'female') }
    let!(:child) { create(:person, first_name: 'Bob', last_name: 'Doe', gender: 'male') }

    before do
      child.parentship.update!(father: father, mother: mother)
    end

    it 'returns 401 without token' do
      get family_chart_api_v1_people_path
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns family-chart compatible json nodes' do
      get family_chart_api_v1_people_path, headers: { 'Authorization' => "Bearer #{bearer_token}" }

      expect(response).to be_successful
      payload = JSON.parse(response.body)
      child_node = payload.find { |node| node['id'] == child.id.to_s }

      expect(child_node).not_to be_nil
      expect(child_node['data']['gender']).to eq('M')
      expect(child_node['rels']['parents']).to contain_exactly(father.id.to_s, mother.id.to_s)
    end

    it 'optionally returns connector data' do
      get family_chart_api_v1_people_path,
          params: { with_connectors: true },
          headers: { 'Authorization' => "Bearer #{bearer_token}" }

      expect(response).to be_successful
      payload = JSON.parse(response.body)
      expect(payload['nodes']).to be_an(Array)
      expect(payload['connectors']).to be_an(Array)
    end
  end

  describe 'POST /api/v1/people/update_tree' do
    let!(:father) { create(:person, first_name: 'John', last_name: 'Doe', gender: 'male') }
    let!(:mother) { create(:person, first_name: 'Jane', last_name: 'Doe', gender: 'female') }
    let!(:child) { create(:person, first_name: 'Bob', last_name: 'Doe', gender: 'male') }

    before do
      child.parentship.update!(father: father, mother: mother)
    end

    it 'returns 401 without token' do
      post update_tree_api_v1_people_path, params: { nodes: [] }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'persists chart data and returns updated nodes' do
      post update_tree_api_v1_people_path,
           params: {
             nodes: [
               {
                 id: father.id.to_s,
                 data: { gender: 'M', 'first name' => 'John', 'last name' => 'Doe Updated' },
                 rels: { spouses: [mother.id.to_s], children: [child.id.to_s] }
               },
               {
                 id: mother.id.to_s,
                 data: { gender: 'F', 'first name' => 'Jane', 'last name' => 'Doe' },
                 rels: { spouses: [father.id.to_s], children: [child.id.to_s] }
               },
               {
                 id: child.id.to_s,
                 data: { gender: 'M', 'first name' => 'Bob', 'last name' => 'Doe' },
                 rels: { parents: [father.id.to_s, mother.id.to_s] }
               }
             ]
           },
           headers: { 'Authorization' => "Bearer #{bearer_token}" },
           as: :json

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body['ok']).to eq(true)
      expect(body['nodes']).to be_an(Array)
      father_node = body['nodes'].find { |n| n['id'] == father.id.to_s }
      expect(father_node['data']['first name']).to eq('John')
      expect(father_node['data']['last name']).to eq('Doe Updated')
      expect(father_node['data']).not_to have_key('name')
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

    it 'stores year-only birth and death flags with placeholder dates' do
      patch api_v1_person_path(person.id),
            params: {
              person: {
                first_name: person.first_name,
                last_name: person.last_name,
                gender: person.gender,
                date_of_birth: '1920-01-01',
                birth_date_year_only: true,
                date_of_death: '1995-01-01',
                death_date_year_only: true
              }
            },
            headers: { 'Authorization' => "Bearer #{bearer_token}" },
            as: :json

      expect(response).to have_http_status(:ok)
      person.reload
      expect(person.date_of_birth).to eq(Date.new(1920, 1, 1))
      expect(person.birth_date_year_only).to be true
      expect(person.date_of_death).to eq(Date.new(1995, 1, 1))
      expect(person.death_date_year_only).to be true

      json = JSON.parse(response.body)
      expect(json['person']['birth_date_year_only']).to be true
      expect(json['person']['death_date_year_only']).to be true
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
