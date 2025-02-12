class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :sso_guid
      t.string :username
      t.string :first_name
      t.string :last_name
      t.string :email
      t.timestamps null: false
    end

    add_index :users, :email, unique: true
  end
end
