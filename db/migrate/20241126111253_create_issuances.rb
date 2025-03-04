class CreateIssuances < ActiveRecord::Migration[7.2]
  def change
    create_table :issuances do |t|
      t.string :status
      t.integer :creator_id
      t.integer :issuer_id
      t.integer :batch_id
      t.integer :quantity
      t.text :allocated_certificates
      t.datetime :issued_at

      t.timestamps
    end
  end
end
