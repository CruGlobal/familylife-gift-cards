ActiveAdmin.register Batch do
  RELOAD_JS_BASED_ON_GIFT_CARD_TYPE = %|var params = new URLSearchParams(location.search); params.set('gift_card_type', $('#batch_gift_card_type').val()); window.location.search = params.toString();|
  RELOAD_JS_HINT = "Changing this value will reload the form to ensure the correct fields are present."

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
    f.object.gift_card_type ||= params[:gift_card_type]

    inputs do
      input :gift_card_type, as: :select, collection: GiftCard::TYPE_DESCRIPTIONS.invert, input_html: { onchange: RELOAD_JS_BASED_ON_GIFT_CARD_TYPE }, hint: RELOAD_JS_HINT
      if f.object.gift_card_type.present? || params[:gift_card_type].present?
        input :description
        input :contact
        if GiftCard::PAID_TYPES.include?(f.object.gift_card_type)
          input :price
        end
        input :registrations_available
        input :associated_product
        input :isbn
        input :begin_use_date, as: :date_time_picker
        input :end_use_date, as: :date_time_picker
        input :expiration_date, as: :date_time_picker

        if GiftCard::TYPE_DEPT == f.object.gift_card_type
          input :gl_code
          input :dept
        end
      end
    end

    f.actions
  end
end
