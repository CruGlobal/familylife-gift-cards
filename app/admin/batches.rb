ActiveAdmin.register Batch do
  actions :all, except: :destroy

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :description, :contact, :gift_card_type, :price, :registrations_available, :begin_use_date, :end_use_date, :expiration_date,
    :associated_product, :isbn, :gl_code, :dept

  index do
    column :id
    column :description
    column :contact
    column :gift_card_type do |record|
      GiftCard::TYPE_DESCRIPTIONS[record.gift_card_type]
    end
    column :price, as: :currency
    column "Reg'n Avail", :registrations_available
    column :begin_use_date
    column :end_use_date
    column "Expn Date", :expiration_date
    column "Product", :associated_product
    column :isbn
    column :gl_code
    column :dept
  end

  form do |f|
    f.semantic_errors

    inputs do
      input :description
      input :contact
      input :gift_card_type, as: :select, collection: GiftCard::TYPE_DESCRIPTIONS.invert
      input :price
      input :registrations_available
      input :begin_use_date, as: :date_time_picker
      input :end_use_date, as: :date_time_picker
      input :expiration_date, as: :date_time_picker
      input :associated_product
      input :isbn

      if GiftCard::PAID_TYPES.include?(f.object.gift_card_type)
        input :gl_code
        input :dept
      end
    end

    f.actions
  end
end
