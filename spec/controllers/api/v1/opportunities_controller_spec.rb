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
      expect(response.body).to eq(gift_card.to_json)
    end
  end

  context "#update" do
    it "updates the photo" do
      # TO DO
    end
  end
end
