class AddIndexes < ActiveRecord::Migration[7.2]
  def change
    add_index :gift_cards, :issuance_id
    add_index :gift_cards, :batch_id
    add_index :gift_cards, :registrations_available
    add_index :gift_cards, :price

    add_index :issuances, :batch_id
    add_index :issuances, :quantity

    add_index :batches, :registrations_available
    add_index :batches, :price
  end
end
