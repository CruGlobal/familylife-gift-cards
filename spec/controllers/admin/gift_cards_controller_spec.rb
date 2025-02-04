require "rails_helper"
require "capybara/rails"

RSpec.describe Admin::GiftCardsController, type: :controller do
  render_views

  let!(:admin) { create(:user) }
  let!(:gift_card) { create(:gift_card, gift_card_type: GiftCard::TYPE_PAID_HALF_PRICE, price: 100.23) }

  before(:each) do
    @user = create(:user)
    sign_in @user
  end

  describe "GET index" do
    it "returns a list of gift cards" do
      get :index
      expect(response.body).to have_content(gift_card.price)
      expect(response.status).to eq(200)
    end
  end
end
