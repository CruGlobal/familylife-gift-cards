class CreateGiftCardTypes < ActiveRecord::Migration[7.2]
  def change
    create_table :gift_card_types do |t|
      t.string :label
      t.string :numbering
      t.string :contact
      t.string :prod_id
      t.string :isbn
      t.string :gl_acct
      t.string :department_number

      t.timestamps
    end
  end
end
