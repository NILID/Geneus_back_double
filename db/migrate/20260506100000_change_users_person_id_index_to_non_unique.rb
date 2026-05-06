# frozen_string_literal: true

class ChangeUsersPersonIdIndexToNonUnique < ActiveRecord::Migration[6.1]
  def change
    remove_index :users, column: :person_id
    add_index :users, :person_id
  end
end
