class Api::V1::GiftCardsController < Api::V1::ApplicationController
  def show
    gift_card = GiftCard.find_by(certificate: params[:id])

    render json: gift_card
  end

  # an update automatically means to use up one registration
  def update
    gift_card = GiftCard.find_by(certificate: params[:id])

    if gift_card.registrations_available.to_i <= 0
      render json: {
        error: "No registrations available",
        status: 403
      }, status: 403
      return
    end

    gift_card.update(registrations_available: gift_card.registrations_available - 1)
    render json: gift_card
  end
end
