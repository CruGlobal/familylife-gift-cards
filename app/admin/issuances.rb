ActiveAdmin.register Issuance do
  actions :all, except: [:edit, :destroy]

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :status, :gift_card_amount, :card_amount, :quantity, :begin_use_date, :end_use_date, :expiration_date, :gift_card_type_id
  #
  # or
  #
  # permit_params do
  #   permitted = [:status, :initiator_id, :card_amount, :quantity, :begin_use_date, :end_use_date, :expiration_date]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  
  index do
    [:initiator, :created_at, :gift_card_type, :card_amount, :quantity, :begin_use_date, :end_use_date, :expiration_date]
  end

	form do |f|
    f.semantic_errors

		inputs do
      input :gift_card_type
      input :card_amount
      input :quantity
      input :begin_use_date, as: :date_time_picker
      input :end_use_date, as: :date_time_picker
      input :expiration_date, as: :date_time_picker

      actions do
        byebug
        if params[:action] == "new"
          submit_tag "Preview", action: :create
        elsif params[:action] == "edit" && issuance.preview?
          submit_tag "Issue Gift Cards", action: :create
        end
      end
    end
  end

  action_item only: :show do
    if issuance.preview?
      link_to 'Issue Gift Cards', issue_admin_issuance_path(issuance), method: :put, data: { confirm: 'Are you sure?' }
    end
  end

  member_action :issue, method: :put do
    resource.issue!
    redirect_to admin_issuance_path(resource), notice: "Gift cards issued!"
  end 

  before_create do |issuance|
    issuance.initiator = Person.first # TODO current_user
  end
end
