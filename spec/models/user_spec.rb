require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should belong_to(:account).optional }
    it { should have_many(:deliveries).dependent(:destroy) }
    it { should have_many(:location_pings).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:phone) }
    it { should validate_presence_of(:role) }
    it { should validate_presence_of(:status) }

    it 'validates phone format' do
      expect(build(:user, phone: '+5511999999999')).to be_valid
      expect(build(:user, phone: '11999999999')).to be_valid
      expect(build(:user, phone: 'invalid')).not_to be_valid
    end

    context 'when user is super_admin' do
      subject { build(:user, role: :super_admin) }

      it 'does not require account' do
        subject.account = nil
        expect(subject).to be_valid
      end
    end

    context 'when user is not super_admin' do
      subject { build(:user, role: :admin) }

      it 'requires account' do
        subject.account = nil
        expect(subject).not_to be_valid
      end
    end
  end

  describe 'enums' do
    it { should define_enum_for(:role).with_values(
      user: 0, store_manager: 1, courier: 2, admin: 3, super_admin: 4
    ) }

    it { should define_enum_for(:status).with_values(
      active: 0, inactive: 1, suspended: 2
    ) }
  end

  describe 'scopes' do
    let!(:account1) { create(:account) }
    let!(:account2) { create(:account) }
    let!(:admin_user) { create(:user, :admin, account: account1) }
    let!(:courier_user) { create(:user, role: :courier, account: account2) }
    let!(:active_user) { create(:user, status: :active) }
    let!(:inactive_user) { create(:user, status: :inactive) }

    describe '.by_account' do
      it 'filters users by account' do
        expect(User.by_account(account1)).to include(admin_user)
        expect(User.by_account(account1)).not_to include(courier_user)
      end
    end

    describe '.by_role' do
      it 'filters users by role' do
        expect(User.by_role(:admin)).to include(admin_user)
        expect(User.by_role(:admin)).not_to include(courier_user)
      end
    end

    describe '.active_users' do
      it 'returns only active users' do
        expect(User.active_users).to include(active_user)
        expect(User.active_users).not_to include(inactive_user)
      end
    end
  end

  describe 'callbacks' do
    describe 'before_create' do
      it 'generates api_token' do
        user = build(:user, api_token: nil)
        expect { user.save! }.to change { user.api_token }.from(nil)
        expect(user.api_token).to be_present
        expect(user.api_token.length).to eq(64)
      end
    end

    describe 'before_validation' do
      it 'normalizes phone number' do
        user = build(:user, phone: '(11) 99999-9999')
        user.valid?
        expect(user.phone).to eq('+5511999999999')
      end
    end

    describe 'after_create' do
      it 'sends welcome email' do
        expect(UserMailer).to receive(:welcome_email).and_return(double(deliver_later: true))
        create(:user)
      end
    end
  end

  describe 'instance methods' do
    let(:user) { create(:user, first_name: 'João', last_name: 'Silva') }

    describe '#full_name' do
      it 'returns concatenated first and last name' do
        expect(user.full_name).to eq('João Silva')
      end
    end

    describe '#initials' do
      it 'returns uppercase initials' do
        expect(user.initials).to eq('JS')
      end
    end

    describe '#active?' do
      it 'returns true for active users' do
        user.update(status: :active)
        expect(user.active?).to be true
      end

      it 'returns false for inactive users' do
        user.update(status: :inactive)
        expect(user.active?).to be false
      end
    end

    describe '#can_manage_account?' do
      let(:account) { create(:account) }
      let(:other_account) { create(:account) }

      context 'when user is super_admin' do
        let(:user) { create(:user, role: :super_admin) }

        it 'returns true for any account' do
          expect(user.can_manage_account?(account)).to be true
          expect(user.can_manage_account?(other_account)).to be true
        end
      end

      context 'when user is admin of the account' do
        let(:user) { create(:user, role: :admin, account: account) }

        it 'returns true for own account' do
          expect(user.can_manage_account?(account)).to be true
        end

        it 'returns false for other account' do
          expect(user.can_manage_account?(other_account)).to be false
        end
      end

      context 'when user is regular user' do
        let(:user) { create(:user, role: :user, account: account) }

        it 'returns false' do
          expect(user.can_manage_account?(account)).to be false
        end
      end
    end

    describe '#regenerate_api_token!' do
      it 'regenerates and saves new api_token' do
        old_token = user.api_token
        user.regenerate_api_token!
        expect(user.api_token).not_to eq(old_token)
        expect(user.reload.api_token).not_to eq(old_token)
      end
    end
  end

  describe 'class methods' do
    describe '.search' do
      let!(:user1) { create(:user, first_name: 'João', last_name: 'Silva', email: 'joao@test.com') }
      let!(:user2) { create(:user, first_name: 'Maria', last_name: 'Santos', email: 'maria@test.com') }

      it 'searches by first_name' do
        results = User.search('João')
        expect(results).to include(user1)
        expect(results).not_to include(user2)
      end

      it 'searches by last_name' do
        results = User.search('Santos')
        expect(results).to include(user2)
        expect(results).not_to include(user1)
      end

      it 'searches by email' do
        results = User.search('joao@test.com')
        expect(results).to include(user1)
        expect(results).not_to include(user2)
      end

      it 'returns empty result for blank query' do
        expect(User.search('')).to eq(User.none)
        expect(User.search(nil)).to eq(User.none)
      end
    end
  end
end
