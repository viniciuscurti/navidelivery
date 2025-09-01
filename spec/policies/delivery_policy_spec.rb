require 'rails_helper'

RSpec.describe DeliveryPolicy do
  subject { described_class }

  let(:account) { Account.create!(name: 'Acc Test') }
  let(:other_account) { Account.create!(name: 'Other') }
  let(:user) { User.create!(account: account, email: 'u@test.com', password: 'password123') }
  let(:delivery) { Delivery.create!(account: account, store: Store.create!(account: account, name: 'S1'), status: 'created') }

  permissions :index?, :create? do
    it 'permite usuário autenticado' do
      expect(subject).to permit(user, Delivery)
    end
  end

  permissions :show?, :update?, :destroy? do
    it 'permite dono' do
      expect(subject).to permit(user, delivery)
    end

    it 'nega outro tenant' do
      other_user = User.create!(account: other_account, email: 'x@test.com', password: 'password123')
      expect(subject).not_to permit(other_user, delivery)
    end
  end
end

