# frozen_string_literal: true

class AddLocationCoordinatesToPeople < ActiveRecord::Migration[6.1]
  def change
    change_table :people, bulk: true do |t|
      t.decimal :birth_latitude, precision: 10, scale: 7
      t.decimal :birth_longitude, precision: 10, scale: 7
      t.decimal :death_latitude, precision: 10, scale: 7
      t.decimal :death_longitude, precision: 10, scale: 7
    end
  end
end
