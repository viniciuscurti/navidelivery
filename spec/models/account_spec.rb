require 'rails_helper'

RSpec.describe Account, type: :model do
  it "is valid with a name" do
    expect(Account.new(name: "Empresa")).to be_valid
  end
end

