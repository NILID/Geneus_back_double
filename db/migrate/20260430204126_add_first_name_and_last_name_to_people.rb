class AddFirstNameAndLastNameToPeople < ActiveRecord::Migration[6.1]
  def change
    add_column :people, :first_name, :string, default: nil
    add_column :people, :last_name, :string, default: nil
  end
end
