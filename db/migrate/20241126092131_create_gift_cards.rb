class CreateGiftCards < ActiveRecord::Migration[7.2]
  def change
    create_table :gift_cards do |t|
      t.datetime :expiration_date
      t.integer :registrations_available
      t.string :associated_product
      t.decimal :certificate_value
      t.string :gl_code

      t.timestamps
    end
  end
end
