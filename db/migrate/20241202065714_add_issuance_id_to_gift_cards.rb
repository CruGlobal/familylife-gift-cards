class AddIssuanceIdToGiftCards < ActiveRecord::Migration[7.2]
  def change
    add_column :gift_cards, :issuance_id, :integer
  end
end
