class AddExtraFieldsToGiftCards < ActiveRecord::Migration[7.2]
  def change
    add_column :gift_cards, :prod, :string
    add_column :gift_cards, :isbn, :string
    add_column :gift_cards, :gl_acct, :string
    add_column :gift_cards, :department_number, :string
  end
end
