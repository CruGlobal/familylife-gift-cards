require "rails_helper"
require "capybara/rails"

RSpec.describe Admin::BatchesController, type: :controller do
  render_views

  let!(:admin) { create(:user) }

  before(:each) do
    @user = create(:user)
    sign_in @user
  end

  describe "GET index" do
    it "returns batches" do
      # Prepare
      batch_paid = create(:batch_paid)
      batch_dept = create(:batch_dept)

      # Test
      get :index

      # Verify
      expect(response.status).to eq(200)
      expect(response.body).to have_content(batch_paid.description)
      expect(response.body).to have_content(batch_dept.description)
    end
  end

  describe "GET new" do
    it "renders form for new paid type batch" do
      # Test
      get :new, params: {gift_card_type: GiftCard::TYPE_PAID_FULL_PRICE}

      # Verify
      expect(response.status).to eq(200)
      expect(response.body).to have_field("Description")
      expect(response.body).to have_field("Contact")
      expect(response.body).to have_field("Price")
      expect(response.body).to have_field("Registrations available")
      expect(response.body).to have_field("Associated product")
      expect(response.body).to have_field("Isbn")
      expect(response.body).to have_field("Begin use date")
      expect(response.body).to have_field("End use date")
      expect(response.body).to have_field("Expiration date")
    end

    it "renders form for new dept type batch" do
      # Test
      get :new, params: {gift_card_type: GiftCard::TYPE_DEPT}

      # Verify
      expect(response.status).to eq(200)
      expect(response.body).to have_field("Description")
      expect(response.body).to have_field("Contact")
      expect(response.body).to have_field("Registrations available")
      expect(response.body).to have_field("Associated product")
      expect(response.body).to have_field("Isbn")
      expect(response.body).to have_field("Begin use date")
      expect(response.body).to have_field("End use date")
      expect(response.body).to have_field("Expiration date")
      expect(response.body).to have_field("Gl code")
      expect(response.body).to have_field("Dept")
    end
  end

  describe "POST create" do
    it "creates batch" do
      # Prepare
      batch_attributes = {
        gift_card_type: "type_dept",
        description: Faker::Lorem.word,
        registrations_available: 2,
        associated_product: "prod",
        begin_use_date: "2125-01-24 04:00",
        end_use_date: "2125-01-24 04:00",
        expiration_date: "2125-01-24 04:00",
        gl_code: "gl code",
        dept: "dept"
      }

      # Test and verify
      expect {
        post :create, params: {batch: batch_attributes}
        puts response.body
      }.to change(Batch, :count).by(1)

      new_batch = Batch.last
      expect(new_batch).to be
      expect(new_batch.gift_card_type).to eq(batch_attributes[:gift_card_type])
      expect(new_batch.description).to eq(batch_attributes[:description])
      expect(new_batch.registrations_available).to eq(batch_attributes[:registrations_available])
      expect(new_batch.associated_product).to eq(batch_attributes[:associated_product])
      expect(new_batch.begin_use_date).to eq(batch_attributes[:begin_use_date])
      expect(new_batch.expiration_date).to eq(batch_attributes[:expiration_date])
      expect(new_batch.gl_code).to eq(batch_attributes[:gl_code])
      expect(new_batch.dept).to eq(batch_attributes[:dept])
      expect(response).to redirect_to(admin_batch_path(new_batch))
    end
  end
end
