ActiveAdmin.register GiftCardType do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  permit_params :label, :numbering, :contact, :prod_id, :isbn, :gl_acct, :department_number
  #
  # or
  #
  # permit_params do
  #   permitted = [:label, :numbering, :contact, :prod_id, :isbn, :gl_acct, :department_number]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  
end
