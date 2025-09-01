require 'rails_helper'

RSpec.describe CourierPolicy do
  subject { described_class }

  let(:account) { Account.create!(name: 'Acc Test') }
  let(:other_account) { Account.create!(name: 'Other') }
  let(:user) { User.create!(account: account, email: 'cour@test.com', password: 'password123') }
  let(:courier) { Courier.create!(account: account, name: 'Moto 1') }

  permissions :index?, :create? do
    it 'permite usuário autenticado' do
      expect(subject).to permit(user, Courier)
    end
  end

  permissions :show?, :update?, :destroy? do
    it 'permite dono' do
      expect(subject).to permit(user, courier)
    end

    it 'nega outro tenant' do
      other_user = User.create!(account: other_account, email: 'x2@test.com', password: 'password123')
      expect(subject).not_to permit(other_user, courier)
    end
  end
end

