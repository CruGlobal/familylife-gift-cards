class CreateApiKeys < ActiveRecord::Migration[7.2]
  def change
    create_table :api_keys do |t|
      t.string :access_token
      t.string :user

      t.timestamps
    end
  end
end
