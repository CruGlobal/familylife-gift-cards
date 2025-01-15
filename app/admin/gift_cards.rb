ActiveAdmin.register GiftCard do
  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :issuance_id, :gift_card_type_id, :certificate, :expiration_date, :registrations_available, :associated_product, :certificate_value, :gl_code, :created_at, :updated_at, :isbn
  #
  # or
  #
  # permit_params do
  #   permitted = [:expiration_date, :registrations_available, :associated_product, :certificate_value, :gl_code, :certificate]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  actions :all, except: [:new]

  index do
    selectable_column
    id_column
    column :gift_card_type
    column :batch
    column :issuance
    column :certificate
    number_column "Value", :certificate_value, as: :currency, unit: "$", sortable: :certificate_value
    # column "Value", :certificate_value do |gift_card|
    #  number_to_currency(gift_card.certificate_value)
    # end
    column :expiration_date
    column "Reg'ns Avail" do |gift_card|
      gift_card.registrations_available
    end
    column "Assoc'd Prod", :associated_product, sortable: :associated_product do |gift_card|
      gift_card.associated_product
    end
    column :gl_code
    column :isbn
    column :created_at
    column :updated_at
    actions
  end
end
