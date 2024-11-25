class CreateApiKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :api_keys do |t|
      t.string :access_token
      t.string :user

      t.timestamps
    end
  end
end
