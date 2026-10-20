class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  def authenticate_active_admin_user!
    redirect_to("/login/new") && return unless current_user
  end

  def after_sign_out_path_for(_resource_or_scope)
    id_token = session[:id_token]
    session.clear
    if id_token.present?
      "#{ENV.fetch("OKTA_ISSUER")}/v1/logout?id_token_hint=#{id_token}&post_logout_redirect_uri=#{request.base_url}"
    else
      "/"
    end
  end
end
