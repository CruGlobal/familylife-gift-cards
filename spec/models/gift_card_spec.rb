require "rails_helper"

RSpec.describe GiftCard, type: :model do
  context "#ransackable_attributes" do
    it "returns a list of attributes" do
      GiftCard.ransackable_attributes.each do |attribute|
        expect(GiftCard.column_names).to include(attribute)
      end
    end
  end

  context "#ransackable_associations" do
    it "returns a list of associations" do
      batch = GiftCard.new
      GiftCard.ransackable_associations.each do |attribute|
        expect(batch.respond_to?(attribute)).to be true
      end
    end
  end
end
