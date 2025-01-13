ActiveAdmin.register Issuance do
  # actions :all, except: [:edit, :destroy]

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :batch_id, :quantity
  #
  # or
  #
  # permit_params do
  #   permitted = [:status, :initiator_id, :price, :quantity]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end

  filter :creator
  filter :issuer
  filter :gift_card_type
  filter :status
  filter :quantitiy
  filter :allocated_certificates
  filter :numbering
  filter :issued_at
  filter :created_at
  filter :updated_at

  index do
    id_column
    tag_column :status
    column :batch
    column :created_at
    column :gift_card_type
    column :creator
    column :issuer
    number_column :price, as: :currency, unit: "$"
    column :quantity
    column :min_certificate do |issuance|
      issuance.allocated_certificates.to_s.split(Issuance::CERTIFICATE_DISPLAY_SEPARATOR).first
    end
    column :max_certificate do |issuance|
      issuance.allocated_certificates.to_s.split(Issuance::CERTIFICATE_DISPLAY_SEPARATOR).last
    end
    column :used do |issuance|
      used = issuance.gift_cards.where(registrations_available: 0).count
      total = issuance.gift_cards.count
      raw("#{number_with_delimiter(used)} / #{number_with_delimiter(issuance.gift_cards.count)}<br/>(#{(used / total.to_f * 100).round(1)}%)")
    end
  end

  form do |f|
    f.semantic_errors

    inputs do
      input :batch, collection: Batch.order(created_at: :desc).collect { |batch| [ batch.to_s, batch.id ] }
      input :quantity

      actions do
        unless issuance.issued?
          f.action :submit, as: :button, label: "Save and Preview Issuance"
        end
        # f.action :cancel, as: :link, label: 'Cancel', class: 'cancel-link'
        cancel_link
        #         if %w(new create).include?(params[:action])
        #           submit_tag(:create, "Preview Issuance")
        #         elsif params[:action] == "edit" && issuance.preview?
        #           submit_tag(:update, "Preview Issuance")
        #         end
        #         cancel_link
      end
    end
  end

  #   action_item :destroy, only: :show, if: -> { resource.preview? } do
  #     link_to 'Delete Issuance', issue_admin_issuance_path(issuance), method: :destroy, data: { confirm: 'Are you sure?' }
  #   end

  action_item :issue, only: :show, if: -> { resource.previewing? } do
    link_to "Issue Gift Cards", issue_admin_issuance_path(issuance), method: :put, data: { confirm: "Are you sure?" }
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
