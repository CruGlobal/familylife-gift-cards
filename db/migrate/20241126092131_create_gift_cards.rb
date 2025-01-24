class CreateGiftCards < ActiveRecord::Migration[7.2]
  def change
    create_table :gift_cards do |t|
      t.integer :issuance_id
      t.integer :batch_id
      t.decimal :price, precision: 8, scale: 2
      t.string :gift_card_type
      t.string :certificate
      t.date :expiration_date
      t.integer :registrations_available
      t.string :associated_product
      t.string :gl_code
      t.string :isbn


      t.timestamps
    end
  end
end
