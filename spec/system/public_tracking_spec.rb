require 'rails_helper'

RSpec.describe "Public Tracking", type: :system do
  it "shows delivery tracking map" do
    delivery = Delivery.create!(public_token: "abc123", status: "in_progress")
    visit "/track/abc123"
    expect(page).to have_content("Rastreamento da Entrega")
    expect(page).to have_css("#map")
  end
end

