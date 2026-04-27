# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FamilyChart::RelationshipIndex do
  let!(:father) { create(:person, name: 'Father Doe', gender: 'male') }
  let!(:mother) { create(:person, name: 'Mother Doe', gender: 'female') }
  let!(:child) { create(:person, name: 'Child Doe', gender: 'male') }

  before do
    child.parentship.update!(father: father, mother: mother)
  end

  describe '#rels_for' do
    it 'matches Person#family_chart_relationships for indexed people (same edges, order-insensitive per list)' do
      people = [father, mother, child]
      index = described_class.new(people)

      people.each do |person|
        legacy = person.family_chart_relationships
        indexed = index.rels_for(person)
        expect(indexed.keys).to match_array(legacy.keys)
        legacy.each do |key, values|
          expect(indexed[key]).to match_array(values)
        end
      end
    end

    it 'uses chart_id when present for edge targets' do
      father.update!(chart_id: 'p-father')
      mother.update!(chart_id: 'p-mother')
      child.update!(chart_id: 'p-child')

      index = described_class.new([child])
      expect(index.rels_for(child)[:parents]).to contain_exactly('p-father', 'p-mother')
    end
  end
end
