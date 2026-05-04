# frozen_string_literal: true

class AddPersonIdToUsers < ActiveRecord::Migration[6.1]
  def change
    add_reference :users, :person, foreign_key: { to_table: :people }, null: true, index: { unique: true }
  end
end
