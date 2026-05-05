# frozen_string_literal: true

class AddRoleToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :role, :string, null: false, default: 'user'
    add_index :users, :role
  end
end
