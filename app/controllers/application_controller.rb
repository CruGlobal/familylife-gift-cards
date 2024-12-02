class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  def current_admin_user
    # TODO replace with okta user
    Person.first
  end

  def destroy_admin_user_session_path
    "TODO"
  end
end
