class CreateAuthentications < ActiveRecord::Migration[7.2]
  def change
    create_table :authentications do |t|
      t.integer :person_id
      t.string :provider
      t.string :uid
      t.string :token
      t.string :username

      t.timestamps
    end
  end
end
