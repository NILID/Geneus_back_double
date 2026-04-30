# frozen_string_literal: true

class RemoveNameFromPeople < ActiveRecord::Migration[6.1]
  def up
    Person.reset_column_information
    say_with_time 'Backfill first_name/last_name from legacy name' do
      Person.find_each do |p|
        next if p.read_attribute(:first_name).present?

        raw = p.read_attribute(:name)
        next if raw.blank?

        parts = raw.to_s.strip.split
        p.update_columns(
          first_name: parts.first,
          last_name: (parts.length > 1 ? parts[1..].join(' ') : nil)
        )
      end
    end

    remove_column :people, :name, :string
  end

  def down
    add_column :people, :name, :string

    Person.reset_column_information
    say_with_time 'Restore name from first_name and last_name' do
      Person.find_each do |p|
        combined = [p.first_name, p.last_name].compact_blank.join(' ')
        p.update_column(:name, combined.presence || 'Unknown')
      end
    end
  end
end
