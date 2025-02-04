require "rails_helper"

RSpec.describe Issuance, type: :model do
  let(:batch) { create(:batch_dept) }
  let(:issuance) { create(:issuance, batch: batch) }
  let!(:gift_card_1) { create(:gift_card, batch: batch, issuance: issuance) }

  context "#ransackable_attributes" do
    it "returns a list of attributes" do
      Issuance.ransackable_attributes.each do |attribute|
        expect(Issuance.column_names).to include(attribute)
      end
    end
  end

  context "#ransackable_associations" do
    it "returns a list of associations" do
      batch = Issuance.new
      Issuance.ransackable_attributes.each do |attribute|
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

      gift_card = GiftCard.last
      batch = gift_card.batch
      expect(gift_card.registrations_available).to eq(batch.registrations_available)
      expect(gift_card.price).to eq(batch.price)
      expect(gift_card.expiration_date).to eq(batch.expiration_date)
      expect(gift_card.issuance).to eq(issuance)
      expect(gift_card.batch).to eq(batch)
      expect(gift_card.isbn).to eq(batch.isbn)
      expect(gift_card.associated_product).to eq(batch.associated_product)
      expect(gift_card.gl_code).to eq(batch.gl_code)
    end
  end

  context "#set_allocated_certificates" do
    it "sets allocated_certificates text field" do
      issuance.update(quantity: 5)
      allow(issuance).to receive(:largest_existing_number_in_certificate).and_return(5)
      issuance.set_allocated_certificates
      expect(issuance.allocated_certificates).to eq("DEP0000060, DEP0000070, DEP0000080, DEP0000090, DEP0000100")
    end
  end

  context "#leading_certificate_4_digit_number" do
    let(:dept_batch) { create(:batch_dept) }
    let(:dept_issuance) { create(:issuance, batch: dept_batch) }
    let(:paid_batch) { create(:batch_paid) }
    let(:paid_issuance) { create(:issuance, batch: paid_batch, quantity: 5) }

    it "uses batch for dept cards" do
      expect(dept_issuance.leading_certificate_4_digit_number).to eq("DEP0")
    end

    it "uses price for paid cards" do
      expect(paid_issuance.leading_certificate_4_digit_number).to eq("3000")
    end
  end

  context "#largest_existing_number_in_certificate" do
  end
end
