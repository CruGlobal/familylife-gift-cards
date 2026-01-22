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

  context "#validate" do
    let(:gift_card_with_registrations) { create(:gift_card, certificate: "cert_valid", registrations_available: 10) }
    let(:gift_card_no_registrations) { create(:gift_card, certificate: "cert_no_reg", registrations_available: 1) }
    let(:gift_card_expired) { create(:gift_card, certificate: "cert_expired", registrations_available: 10, expiration_date: Date.yesterday) }
    let(:gift_card_expires_today) { create(:gift_card, certificate: "cert_today", registrations_available: 10, expiration_date: Date.today) }
    let(:gift_card_expires_future) { create(:gift_card, certificate: "cert_future", registrations_available: 10, expiration_date: Date.tomorrow) }
    let(:gift_card_no_expiration) { create(:gift_card, certificate: "cert_no_exp", registrations_available: 10, expiration_date: nil) }

    it "returns valid: true when gift card has registrations available" do
      get :validate, params: {access_token: api_key.access_token, id: gift_card_with_registrations.certificate, format: :json}
      expect(response).to have_http_status(200)
      parsed_response = JSON.parse(response.body)
      expect(parsed_response["valid"]).to eq(true)
      expect(parsed_response["gift_card"]["certificate"]).to eq(gift_card_with_registrations.certificate)
      expect(parsed_response["gift_card"]["registrations_available"]).to eq(10)
    end

    it "does not modify registrations_available" do
      get :validate, params: {access_token: api_key.access_token, id: gift_card_with_registrations.certificate, format: :json}
      gift_card_with_registrations.reload
      expect(gift_card_with_registrations.registrations_available).to eq(10)
    end

    it "returns valid: false when no registrations available" do
      get :validate, params: {access_token: api_key.access_token, id: gift_card_no_registrations.certificate, format: :json}
      expect(response).to have_http_status(403)
      parsed_response = JSON.parse(response.body)
      expect(parsed_response["valid"]).to eq(false)
      expect(parsed_response["error"]).to eq("No registrations available")
    end

    it "handles gift card not found" do
      get :validate, params: {access_token: api_key.access_token, id: "not existing", format: :json}
      expect(response).to have_http_status(404)
    end

    it "rejects an invalid access token" do
      get :validate, params: {access_token: "invalid", id: gift_card_with_registrations.certificate, format: :json}
      expect(response).to have_http_status(401)
    end

    it "returns valid: false when gift card has expired" do
      get :validate, params: {access_token: api_key.access_token, id: gift_card_expired.certificate, format: :json}
      expect(response).to have_http_status(403)
      parsed_response = JSON.parse(response.body)
      expect(parsed_response["valid"]).to eq(false)
      expect(parsed_response["error"]).to eq("Gift card has expired")
    end

    it "returns valid: true when gift card expires today" do
      get :validate, params: {access_token: api_key.access_token, id: gift_card_expires_today.certificate, format: :json}
      expect(response).to have_http_status(200)
      parsed_response = JSON.parse(response.body)
      expect(parsed_response["valid"]).to eq(true)
    end

    it "returns valid: true when gift card expires in the future" do
      get :validate, params: {access_token: api_key.access_token, id: gift_card_expires_future.certificate, format: :json}
      expect(response).to have_http_status(200)
      parsed_response = JSON.parse(response.body)
      expect(parsed_response["valid"]).to eq(true)
    end

    it "returns valid: true when expiration_date is nil" do
      get :validate, params: {access_token: api_key.access_token, id: gift_card_no_expiration.certificate, format: :json}
      expect(response).to have_http_status(200)
      parsed_response = JSON.parse(response.body)
      expect(parsed_response["valid"]).to eq(true)
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
      expect(JSON.parse(response.body)["error"]).to eq("No registrations available")
    end

    it "handles an expired gift card" do
      gift_card.update(registrations_available: 10, expiration_date: 1.day.ago)
      put :update, params: {access_token: api_key.access_token, id: gift_card.certificate, format: :json}
      expect(response).to have_http_status(403)
      expect(JSON.parse(response.body)["error"]).to eq("Gift card has expired")
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
