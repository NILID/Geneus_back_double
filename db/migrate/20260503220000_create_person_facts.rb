# frozen_string_literal: true

class CreatePersonFacts < ActiveRecord::Migration[6.1]
  def change
    create_table :person_facts do |t|
      t.references :person, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false

      t.timestamps
    end
  end
end
