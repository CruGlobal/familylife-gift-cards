class CreateIssuances < ActiveRecord::Migration[7.2]
  def change
    create_table :issuances do |t|
      t.string :status
      t.integer :initiator_id
      t.decimal :card_amount
      t.integer :quantity
      t.datetime :begin_use_date
      t.datetime :end_use_date
      t.datetime :expiration_date
      t.integer :gift_card_type_id

      t.timestamps
    end
  end
end
