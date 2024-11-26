class AddCertificateIdToGiftCards < ActiveRecord::Migration[7.2]
  def change
    add_column :gift_cards, :certificate_id, :string
  end
end
