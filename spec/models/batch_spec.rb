require 'rails_helper'

RSpec.describe Batch, type: :model do
  context "#new" do
    it "default registrations_available to 2" do
      expect(Batch.new.registrations_available).to eq(2)
    end
  end

  context "#description" do
    it "return description" do
      expect(Batch.new(description: "test").to_s).to eq("test")
    end
  end

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
end
