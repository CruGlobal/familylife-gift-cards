class CreateIssuances < ActiveRecord::Migration[7.2]
  def change
    create_table :issuances do |t|
      t.string :status
      t.integer :creator_id
      t.integer :issuer_id
      t.decimal :card_amount
      t.integer :quantity
      t.datetime :begin_use_date
      t.datetime :end_use_date
      t.datetime :expiration_date
      t.integer :gift_card_type_id
      t.text :allocated_certificates
      t.string :numbering
      t.datetime :issued_at

      t.timestamps
    end
  end
end
