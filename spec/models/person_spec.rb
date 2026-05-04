require 'rails_helper'

RSpec.describe Person, type: :model do

  let(:person) { build(:person) }

  it 'must have gender' do
    expect(person.valid?).to be true
    expect(person.errors).to be_empty
  end

  it 'must have gender' do
    person.gender = nil
    expect(person.valid?).to be false
    expect(person.errors[:gender]).not_to be_empty
  end

  it 'must have gender inclusion male/female' do
    person.gender = 'women'
    expect(person.valid?).to be false
    expect(person.errors[:gender]).not_to be_empty
  end

  it 'death must be after birth ' do
    person.date_of_birth = DateTime.now
    person.date_of_death = DateTime.now - 1.day
    expect(person.valid?).to be false
    expect(person.errors[:date_of_death]).not_to be_empty
    expect(person.errors[:date_of_birth]).not_to be_empty
  end

  it 'birth must be before current date ' do
    person.date_of_birth = DateTime.now + 1.day
    expect(person.valid?).to be false
    expect(person.errors[:date_of_birth]).not_to be_empty
  end

  it 'death must be before current date ' do
    person.date_of_death = DateTime.now + 1.day
    expect(person.valid?).to be false
    expect(person.errors[:date_of_death]).not_to be_empty
  end

  it 'first_name must have minimum 1 symbol' do
    person.first_name = ''
    expect(person.valid?).to be false
    expect(person.errors[:first_name]).not_to be_empty
  end

  it 'clears birth_date_year_only when date_of_birth is blank' do
    p = build(:person, date_of_birth: nil, birth_date_year_only: true)
    expect(p).to be_valid
    expect(p.birth_date_year_only).to be false
  end

  it 'clears death_date_year_only when date_of_death is blank' do
    p = build(:person, date_of_death: nil, death_date_year_only: true)
    expect(p).to be_valid
    expect(p.death_date_year_only).to be false
  end

  describe '#family_chart_node' do
    let!(:father) { create(:person, first_name: 'Father', last_name: 'Doe', gender: 'male') }
    let!(:mother) { create(:person, first_name: 'Mother', last_name: 'Doe', gender: 'female') }
    let!(:child) { create(:person, first_name: 'Child', last_name: 'Doe', gender: 'male') }

    before do
      child.parentship.update!(father: father, mother: mother)
    end

    it 'exports id, data and rels in family-chart format' do
      node = child.family_chart_node

      expect(node[:id]).to eq(child.id.to_s)
      expect(node[:person_id]).to eq(child.id)
      expect(node[:data]['gender']).to eq('M')
      expect(node[:rels][:parents]).to contain_exactly(father.id.to_s, mother.id.to_s)
    end
  end
end
