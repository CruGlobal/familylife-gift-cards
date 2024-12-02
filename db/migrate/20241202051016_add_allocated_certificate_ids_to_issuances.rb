class AddAllocatedCertificateIdsToIssuances < ActiveRecord::Migration[7.2]
  def change
    add_column :issuances, :allocated_certificates, :text
  end
end
