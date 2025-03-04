class Api::V1::ApplicationController < ApplicationController
  before_action :restrict_access

  respond_to :json

  skip_forgery_protection

  protected

  def restrict_access
    api_key = ApiKey.find_by(access_token: oauth_access_token)
    unless api_key
      render json: {error: "You either didn't pass in an access token, or the token you did pass in was wrong."},
        status: :unauthorized,
        callback: params[:callback]
      return false
    end
    @current_user = api_key.user
    true
  end

  def oauth_access_token
    @oauth_access_token ||= params[:access_token] || oauth_access_token_from_header
  end

  # grabs access_token from header if one is present
  def oauth_access_token_from_header
    auth_header = request.env["HTTP_AUTHORIZATION"] || ""
    match = auth_header.match(/^token\s(.*)/) || auth_header.match(/^Bearer\s(.*)/)
    return match[1] if match.present?

    false
  end
end
