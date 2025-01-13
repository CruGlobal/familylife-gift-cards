class CreateBatches < ActiveRecord::Migration[7.2]
  def change
    create_table :batches do |t|
      t.string :description
      t.string :contact
      t.string :gift_card_type
      t.decimal :price, precision: 8, scale: 2
      t.integer :registrations_available

      t.datetime :begin_use_date
      t.datetime :end_use_date
      t.datetime :expiration_date

      t.string :associated_product
      t.string :isbn # optional

      # dept cards have these
      t.string :gl_code
      t.string :dept

      t.timestamps
    end
  end
end
