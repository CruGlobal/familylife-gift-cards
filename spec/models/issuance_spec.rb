require "rails_helper"

RSpec.describe Issuance, type: :model do
  let(:batch) { create(:batch_dept) }
  let(:issuance) { create(:issuance, batch: batch) }

  context "#ransackable_attributes" do
    it "returns a list of attributes" do
      Batch.ransackable_attributes.each do |attribute|
        expect(Batch.column_names).to include(attribute)
      end
    end
  end

  context "#ransackable_associations" do
    it "returns a list of associations" do
      batch = Batch.new
      Batch.ransackable_attributes.each do |attribute|
        expect(batch.respond_to?(attribute)).to be true
      end
    end
  end

  context "state machine" do
    it "starts at configuring" do
      expect(Issuance.new.status).to eq("configuring")
    end

    it "transitions from configuring to previewing" do
      issuance.update_column(:status, "configuring")
      expect(issuance).to receive(:set_allocated_certificates)
      issuance.preview!
      expect(issuance.reload.status).to eq("previewing")
    end

    it "transitions from previewing to issued and calls create gift cards" do
      expect(issuance).to receive(:create_gift_cards)
      issuance.issue!
    end
  end

  context "#to_s" do
    it "gives the right string when previewing" do
      expect(issuance.to_s).to eq("Gift Card Issuance (Preview)")
    end
    it "gives the right string when issued" do
      issuance.issue!
      expect(issuance.to_s).to eq("Issuance by #{issuance.issuer.full_name} #{issuance.created_at} (#{issuance.quantity}#{" @ $#{issuance.price}" if issuance.price})")
    end
  end

  context "#create_gift_cards" do
    it "creates gift cards" do
      #       gift_card.registrations_available = batch.registrations_available
      #       gift_card.price = price
      #       gift_card.expiration_date = batch.expiration_date
      #       gift_card.gift_card_type = batch.gift_card_type
      #       gift_card.issuance = self
      #       gift_card.batch = batch
      #       gift_card.isbn = batch.isbn
      #       gift_card.associated_product = batch.associated_product
      #       gift_card.gl_code = batch.gl_code
      #       gift_card.save!
      expect do
        issuance.create_gift_cards
      end.to change(GiftCard, :count).by(issuance.quantity)
    end
  end
end
