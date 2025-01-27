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
    f.object.gift_card_type ||= params[:gift_card_type]

    inputs do
      input :gift_card_type, as: :select, collection: GiftCard::TYPE_DESCRIPTIONS.invert, input_html: {onchange: reload_js_based_on_gift_card_type}, hint: reload_js_hint
      if f.object.gift_card_type.present? || params[:gift_card_type].present?
        input :description
        input :contact
        if GiftCard::PAID_TYPES.include?(f.object.gift_card_type)
          input :price
        end
        input :registrations_available
        input :associated_product
        input :isbn
        input :begin_use_date, as: :date_picker, input_html: { style: "width: 120px" }
        input :end_use_date, as: :date_picker, input_html: { style: "width: 120px" }
        input :expiration_date, as: :date_picker, input_html: { style: "width: 120px" }

        if f.object.gift_card_type == GiftCard::TYPE_DEPT
          input :gl_code, hint: "(63301-dept-project)"
          input :dept, hint: "(4-digit dept, ex 4240)"
        end
      end
    end

    f.actions
  end
end
