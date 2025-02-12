require "rails_helper"

RSpec.describe ApiKey, type: :model do
  context "#generate_access_record" do
    it "checks if access token is taken and generates a new one" do
      expect(ApiKey).to receive(:exists?)
      api_key = ApiKey.create!
      expect(api_key.access_token).to_not be_nil
    end
  end

  context "#ransackable_attributes" do
    it "returns a list of attributes" do
      ApiKey.ransackable_attributes.each do |attribute|
        expect(ApiKey.column_names).to include(attribute)
      end
    end
  end

  context "#ransackable_associations" do
    it "returns a list of associations" do
      api_key = ApiKey.new
      ApiKey.ransackable_associations.each do |attribute|
        expect(api_key.respond_to?(attribute)).to be true
      end
    end
  end
end
