require "rails_helper"

RSpec.describe ApiKey, type: :model do
  context "#generate_access_token" do
    it "generates an access token" do
      api_key = ApiKey.create!
      expect(api_key.access_token).to_not be_nil
    end

    it "regenerates the access token when the generated one is taken" do
      tried = []
      allow(ApiKey).to receive(:exists?) { |conditions|
        tried << conditions[:access_token]
        tried.size == 1
      }
      api_key = ApiKey.new
      expect(tried.size).to eq(2)
      expect(tried.last).to_not eq(tried.first)
      expect(api_key.access_token).to eq(tried.last)
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
