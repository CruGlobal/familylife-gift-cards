require "rails_helper"
require "capybara/rails"

RSpec.describe Admin::DashboardController, type: :controller do
  render_views

  let!(:admin) { create(:user) }

  before(:each) do
    @user = create(:user)
    sign_in @user
  end

  describe "GET index" do
    it "renders without error" do
      get :index
      expect(response.status).to eq(200)
    end
  end
end
