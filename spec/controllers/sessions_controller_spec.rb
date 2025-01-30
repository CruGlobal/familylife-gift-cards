# frozen_string_literal: true

require "rails_helper"

RSpec.describe SessionsController, type: :controller do
  before do
    @sso_guid = SecureRandom.uuid
    @uid = "#{Faker::Name.first_name}_#{Faker::Name.last_name}"
    @auth_hash = OpenStruct.new
    @auth_hash.uid = @uid
    @auth_hash.extra = OpenStruct.new
    @auth_hash.extra.raw_info = OpenStruct.new
    @auth_hash.extra.raw_info.ssoguid = @sso_guid
    @auth_hash.extra.raw_info.preferred_username = Faker::Internet.email
    @auth_hash.extra.id_token = "id_token"
    @auth_hash.info = OpenStruct.new
    @auth_hash.info.first_name = Faker::Name.first_name
    @auth_hash.info.last_name = Faker::Name.last_name
    @auth_hash.info.email = Faker::Internet.email
    OmniAuth.config.test_mode = true
    request.env["omniauth.auth"] = @auth_hash
  end

  describe "#create" do
    it "should successfully login an existing user" do
      # Prepare
      user = create(:user, sso_guid: @sso_guid)
      request.env["devise.mapping"] = Devise.mappings[:user]

      # Test
      post :oktaoauth

      # Verify
      expect(controller.current_user.id).to eq(user.id)
    end

    it "should successfully create a user" do
      # Prepare
      request.env["devise.mapping"] = Devise.mappings[:user]

      # Test
      post :oktaoauth

      # Verify
      # expect(controller.current_user.id).to eq(user.id)

      expect(controller.current_user).to be
    end
  end

  context "#after_sign_out_path_for" do
    it "returns a valid url when id token present" do
      ENV["OKTA_ISSUER"] = "okta_issuer"
      session = double("session")
      allow(controller).to receive(:session).and_return(session)
      expect(session).to receive(:[]).with(:id_token).and_return("12345")
      expect(session).to receive(:clear)
      expect(controller.after_sign_out_path_for(nil)).to eq("okta_issuer/v1/logout?id_token_hint=12345&post_logout_redirect_uri=http://test.host")
    end

    it "returns a valid url when id token not present" do
      expect(controller.after_sign_out_path_for(nil)).to eq("/")
    end
  end
end
