class Api::V1::GiftCardsController < Api::V1::ApplicationController
  before_action :load_gift_card_from_certificate

  def show
    @gift_card = GiftCard.find_by(certificate: params[:id])

    render json: @gift_card
  end

  # validates if a gift card can be used without actually using it
  def validate
    if @gift_card.registrations_available.to_i <= 1
      render json: {
        valid: false,
        error: "No registrations available",
        status: 403
      }, status: 403
      return
    end

    if @gift_card.expiration_date && @gift_card.expiration_date < Date.today
      render json: {
        valid: false,
        error: "Gift card has expired",
        status: 403
      }, status: 403
      return
    end

    render json: {
      valid: true,
      gift_card: @gift_card
    }
  end

  # an update automatically means to use up one registration
  def update
    if @gift_card.registrations_available.to_i <= 1
      render json: {
        error: "No registrations available",
        status: 403
      }, status: :forbidden
      return
    end

    if @gift_card.expired?
      render json: {
        error: "Gift card has expired",
        status: 403
      }, status: :forbidden
      return
    end

    @gift_card.update(registrations_available: @gift_card.registrations_available - 2)
    render json: @gift_card
  end

  private

  def load_gift_card_from_certificate
    @gift_card = GiftCard.find_by(certificate: params[:id])

    unless @gift_card
      render json: {
        error: "No gift card found by that certificate",
        status: 404
      }, status: :not_found
    end
  end
end
