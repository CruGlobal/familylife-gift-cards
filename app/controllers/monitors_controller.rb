class MonitorsController < ApplicationController
  #skip_before_action :require_login, raise: false

  def lb
    User.first
    render plain: "OK"
  end
end
