require 'rails_helper'

RSpec.describe "Deliveries", type: :request do
  let(:account) { Account.create!(name: "Empresa") }
  let(:store) { Store.create!(account: account, name: "Loja") }

  before { Current.account = account }

  it "creates a delivery" do
    post deliveries_path, params: { delivery: { store_id: store.id, status: "pending" } }
    expect(response).to have_http_status(:created)
  end
end

