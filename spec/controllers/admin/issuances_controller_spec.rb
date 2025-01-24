require "rails_helper"
require "capybara/rails"

RSpec.describe Admin::IssuancesController, type: :controller do
  render_views

  let!(:admin) { create(:user) }
  let!(:batch_paid) { create(:batch_paid) }
  let!(:batch_dept) { create(:batch_dept) }

  before(:each) do
    @user = create(:user)
    sign_in @user
  end

  describe "GET index" do
    it "returns issuances" do
      # Prepare
      create(:issuance, batch: batch_paid)

      # Test
      get :index

      # Verify
      expect(response.status).to eq(200)
      expect(response.body).to have_content(batch_paid.description)
    end
  end

  describe "GET new" do
    it "renders form for new" do
      # Test
      get :new

      # Verify
      expect(response.status).to eq(200)
      expect(response.body).to have_field("Batch")
      expect(response.body).to have_field("Quantity")
    end
  end

  describe "POST create" do
    it "creates issuance" do
      # Prepare
      issuance_attributes = {
        batch_id: batch_paid.id,
        quantity: 5
      }

      # Test and verify
      expect {
        post :create, params: {issuance: issuance_attributes}
        puts response.body
      }.to change(Issuance, :count).by(1)

      new_issuance = Issuance.last
      expect(new_issuance).to be
      expect(new_issuance.batch).to eq(batch_paid)
      expect(new_issuance.quantity).to eq(5)
      expect(new_issuance.allocated_certificates).to eq("3000000010, 3000000020, 3000000030, 3000000040, 3000000050")
      expect(response).to redirect_to(admin_issuance_path(new_issuance))
    end
  end

  context "issue action" do
    let!(:issuance) { create(:issuance, batch: batch_paid, quantity: 5) }

    it "creates gift cards when issue action called" do
      expect {
        post :issue, params: {id: issuance.id}
        puts response.body
      }.to change(GiftCard, :count).by(issuance.quantity)

      gift_card = GiftCard.last
      expect(gift_card.batch).to eq(batch_paid)
      expect(gift_card.issuance).to eq(issuance)
      expect(gift_card.registrations_available).to eq(batch_paid.registrations_available)
      expect(gift_card.price).to eq(batch_paid.price)
      expect(gift_card.expiration_date).to eq(batch_paid.expiration_date)
    end
  end
end
