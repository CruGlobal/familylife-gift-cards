class AddIsbnToGiftCards < ActiveRecord::Migration[7.2]
  def change
    add_column :gift_cards, :isbn, :string
  end
end
