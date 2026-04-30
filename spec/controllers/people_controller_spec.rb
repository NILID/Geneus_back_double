require 'rails_helper'

RSpec.describe PeopleController, type: :controller do

  let!(:person) { create(:person) }
  let(:user) { create(:user) }

  describe "GET #index" do
    it "returns a success response" do
      get :index
      expect(response).to be_successful
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      get :show, params: {id: person}
      expect(response).to be_successful
    end
  end

  describe "POST #update_tree" do
    let!(:father) { create(:person, first_name: 'John', last_name: 'Doe', gender: 'male') }
    let!(:mother) { create(:person, first_name: 'Jane', last_name: 'Doe', gender: 'female') }
    let!(:child) { create(:person, first_name: 'Bob', last_name: 'Doe', gender: 'male') }

    before do
      sign_in user
      child.parentship.update!(father: father, mother: mother)
    end

    it "rejects unauthenticated requests" do
      sign_out user
      post :update_tree, params: { nodes: [] }
      expect(response).to have_http_status(:unauthorized)
    end

    it "persists chart data and returns updated nodes" do
      post :update_tree, params: {
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
      }

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

  describe "GET #family_chart" do
    let!(:father) { create(:person, first_name: 'John', last_name: 'Doe', gender: 'male') }
    let!(:mother) { create(:person, first_name: 'Jane', last_name: 'Doe', gender: 'female') }
    let!(:child) { create(:person, first_name: 'Bob', last_name: 'Doe', gender: 'male') }

    before do
      sign_in user
      child.parentship.update!(father: father, mother: mother)
    end

    it "rejects unauthenticated requests" do
      sign_out user
      get :family_chart, params: { format: :json }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns family-chart compatible json nodes" do
      get :family_chart, params: { format: :json }

      expect(response).to be_successful
      payload = JSON.parse(response.body)
      child_node = payload.find { |node| node['id'] == child.id.to_s }

      expect(child_node).not_to be_nil
      expect(child_node['data']['gender']).to eq('M')
      expect(child_node['rels']['parents']).to contain_exactly(father.id.to_s, mother.id.to_s)
    end

    it "optionally returns connector data" do
      get :family_chart, params: { format: :json, with_connectors: true }

      expect(response).to be_successful
      payload = JSON.parse(response.body)
      expect(payload['nodes']).to be_an(Array)
      expect(payload['connectors']).to be_an(Array)
    end
  end
end
