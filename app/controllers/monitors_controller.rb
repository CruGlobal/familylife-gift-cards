class MonitorsController < ApplicationController
  # skip_before_action :require_login, raise: false

  def lb
    User.first unless Rails.env.staging?
    render plain: "OK"
  end
end
