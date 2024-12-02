ActiveAdmin.register Issuance do
  #actions :all, except: [:edit, :destroy]

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
    id_column
    column :created_at
    column :gift_card_type
    column :creator
    column :issuer
    number_column :card_amount, as: :currency, unit: "$"
    column :quantity
    column :min_certificate do |issuance|
      issuance.allocated_certificates.split(", ").first
    end
    column :max_certificate do |issuance|
      issuance.allocated_certificates.split(", ").last
    end
    column :begin_use_date
    column :end_use_date
    column :expiration_date
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
        unless issuance.issued?
          f.action :submit, as: :button, label: "Save and Preview Issuance"
        end
        #f.action :cancel, as: :link, label: 'Cancel', class: 'cancel-link'
        cancel_link
=begin
        if %w(new create).include?(params[:action])
          submit_tag(:create, "Preview Issuance")
        elsif params[:action] == "edit" && issuance.preview?
          submit_tag(:update, "Preview Issuance")
        end
        cancel_link
=end
      end
    end
  end

=begin
  action_item :destroy, only: :show, if: -> { resource.preview? } do
    link_to 'Delete Issuance', issue_admin_issuance_path(issuance), method: :destroy, data: { confirm: 'Are you sure?' }
  end
=end

  action_item :issue, only: :show, if: -> { resource.preview? } do
    link_to 'Issue Gift Cards', issue_admin_issuance_path(issuance), method: :put, data: { confirm: 'Are you sure?' }
  end

  member_action :issue, method: :put do
    resource.issue!
    resource.update(issuer_id: current_admin_user.id, issued_at: Time.now)
    redirect_to admin_issuance_path(resource), notice: "Gift cards issued!"
  end 

  before_create do |issuance|
    issuance.creator = current_admin_user
  end
end
