ActiveAdmin.register GiftCard do

  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # Uncomment all parameters which should be permitted for assignment
  #
  # permit_params :expiration_date, :registrations_available, :associated_product, :certificate_value, :gl_code, :certificate
  #
  # or
  #
  # permit_params do
  #   permitted = [:expiration_date, :registrations_available, :associated_product, :certificate_value, :gl_code, :certificate]
  #   permitted << :other if params[:action] == 'create' && current_user.admin?
  #   permitted
  # end
  
  actions :all, :except => [:new]
end
