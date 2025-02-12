# frozen_string_literal: true

require "rails_helper"

describe Api::V1::GiftCardsController do
  let(:api_key) { create(:api_key) }
  let!(:gift_card) { create(:gift_card, certificate: "cert") }

  before do
    request.env["HTTP_ACCEPT"] = "application/json"
  end

  context "#show" do
    it "returns gift card info" do
      get :show, params: {access_token: api_key.access_token, id: gift_card.certificate, format: :json}
      expect(JSON.parse(response.body)).to eq(JSON.parse(gift_card.to_json))
    end

    it "handles gift card not found" do
      get :show, params: {access_token: api_key.access_token, id: "not existing", format: :json}
      expect(response).to have_http_status(404)
    end

    it "finds token from HTTP_AUTHORIZATION" do
      request.env["HTTP_AUTHORIZATION"] = "token #{api_key.access_token}"
      get :show, params: {id: "not existing", format: :json}
      expect(response).to have_http_status(404)
    end

    it "rejects an invalid HTTP_AUTHORIZATIO" do
      get :show, params: {access_token: "invalid", id: api_key.access_token, format: :json}
      expect(response).to have_http_status(401)
    end

    it "rejects an invalid HTTP_AUTHORIZATIO" do
      get :show, params: {id: api_key.access_token, format: :json}
      expect(response).to have_http_status(401)
    end
  end

  context "#update" do
    it "handles gift card not found" do
      put :update, params: {access_token: api_key.access_token, id: "not existing", format: :json}
      expect(response).to have_http_status(404)
    end

    it "handles a gift card that doesn't have any more registrations available" do
      gift_card.update(registrations_available: 1)
      put :update, params: {access_token: api_key.access_token, id: gift_card.certificate, format: :json}
      expect(response).to have_http_status(403)
    end

    it "subtracts 2 from registrations_available" do
      gift_card.update(registrations_available: 10)
      put :update, params: {access_token: api_key.access_token, id: gift_card.certificate, format: :json}
      gift_card.reload
      expect(JSON.parse(response.body)).to eq(JSON.parse(gift_card.to_json))
      expect(JSON.parse(response.body)["registrations_available"]).to eq(8)
      expect(gift_card.registrations_available).to eq(8)
    end
  end
end
