require "rails_helper"

RSpec.describe CustomAuthorization, type: :model do
  let(:issuance) { create(:issuance) }
  let(:batch) { create(:batch_paid) }
  let(:issuance_auth) { CustomAuthorization.new(Issuance, create(:user)) }
  let(:batch_auth) { CustomAuthorization.new(Batch, create(:user)) }

  context "#authorized?" do
    it "disallows editing issued Issuance" do
      issuance.update_column(:status, "issued")
      expect(issuance_auth.authorized?(:write, issuance)).to be false
    end

    it "allows editing Issuance that is not already issued" do
      issuance.update_column(:status, "previewing")
      expect(issuance_auth.authorized?(:write, issuance)).to be true
    end

    it "allows reading Issuance that is already issued" do
      issuance.update_column(:status, "issued")
      expect(issuance_auth.authorized?(:read, issuance)).to be true
    end

    it "allows writing other objects" do
      expect(batch_auth.authorized?(:write, batch)).to be true
    end
  end
end
