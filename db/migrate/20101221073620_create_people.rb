class CreatePeople < ActiveRecord::Migration[5.2]
  def change
    create_table :people do |t|
      t.string :first_name, default: nil
      t.string :last_name, default: nil

      t.string :gender
      t.text :bio
      t.date :date_of_birth
      t.date :date_of_death

      t.timestamps
    end
  end
end
