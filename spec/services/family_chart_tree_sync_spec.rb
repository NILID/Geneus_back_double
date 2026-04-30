require 'rails_helper'

RSpec.describe FamilyChartTreeSync do
  describe '#call' do
    let!(:father) { create(:person, first_name: 'John', last_name: 'Doe', gender: 'male') }
    let!(:mother) { create(:person, first_name: 'Jane', last_name: 'Doe', gender: 'female') }
    let!(:child) { create(:person, first_name: 'Bob', last_name: 'Doe', gender: 'male') }

    before do
      child.parentship.update!(father: father, mother: mother)
      father.partnerships.create!(partner: mother)
    end

    it 'updates person attributes from chart data' do
      nodes = [
        {
          'id' => father.id.to_s,
          'data' => { 'gender' => 'M', 'first name' => 'John', 'last name' => 'Doe Updated' },
          'rels' => { 'spouses' => [mother.id.to_s], 'children' => [child.id.to_s] }
        },
        {
          'id' => mother.id.to_s,
          'data' => { 'gender' => 'F', 'first name' => 'Jane', 'last name' => 'Doe' },
          'rels' => { 'spouses' => [father.id.to_s], 'children' => [child.id.to_s] }
        },
        {
          'id' => child.id.to_s,
          'data' => { 'gender' => 'M', 'first name' => 'Bob', 'last name' => 'Doe' },
          'rels' => { 'parents' => [father.id.to_s, mother.id.to_s] }
        }
      ]

      described_class.new(nodes: nodes, removed_ids: []).call

      father.reload
      expect(father.first_name).to eq('John')
      expect(father.last_name).to eq('Doe Updated')
    end

    it 'creates a new person with chart_id for UUID ids' do
      uuid = 'aaaaaaaa-bbbb-4ccc-dddd-eeeeeeeeeeee'
      nodes = [
        {
          'id' => father.id.to_s,
          'data' => { 'gender' => 'M', 'first name' => 'John', 'last name' => 'Doe' },
          'rels' => { 'spouses' => [mother.id.to_s], 'children' => [child.id.to_s] }
        },
        {
          'id' => mother.id.to_s,
          'data' => { 'gender' => 'F', 'first name' => 'Jane', 'last name' => 'Doe' },
          'rels' => { 'spouses' => [father.id.to_s], 'children' => [child.id.to_s] }
        },
        {
          'id' => child.id.to_s,
          'data' => { 'gender' => 'M', 'first name' => 'Bob', 'last name' => 'Doe' },
          'rels' => { 'parents' => [father.id.to_s, mother.id.to_s] }
        },
        {
          'id' => uuid,
          'data' => { 'gender' => 'F', 'first name' => 'New', 'last name' => 'Person' },
          'rels' => {}
        }
      ]

      expect {
        described_class.new(nodes: nodes, removed_ids: []).call
      }.to change(Person, :count).by(1)

      created = Person.find_by(chart_id: uuid)
      expect(created.first_name).to eq('New')
      expect(created.last_name).to eq('Person')
    end

    it 'removes a person when listed in removed_ids' do
      nodes = [
        {
          'id' => father.id.to_s,
          'data' => { 'gender' => 'M', 'first name' => 'John', 'last name' => 'Doe' },
          'rels' => { 'spouses' => [mother.id.to_s] }
        },
        {
          'id' => mother.id.to_s,
          'data' => { 'gender' => 'F', 'first name' => 'Jane', 'last name' => 'Doe' },
          'rels' => { 'spouses' => [father.id.to_s] }
        }
      ]

      expect {
        described_class.new(nodes: nodes, removed_ids: [child.id.to_s]).call
      }.to change(Person, :count).by(-1)

      expect(Person.find_by(id: child.id)).to be_nil
    end
  end
end
