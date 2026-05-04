# frozen_string_literal: true

class AddYearOnlyDateFlagsToPeople < ActiveRecord::Migration[6.1]
  def change
    add_column :people, :birth_date_year_only, :boolean, default: false, null: false
    add_column :people, :death_date_year_only, :boolean, default: false, null: false
  end
end
