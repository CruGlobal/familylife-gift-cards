class AddNumberingToIssuances < ActiveRecord::Migration[7.2]
  def change
    add_column :issuances, :numbering, :string
  end
end
