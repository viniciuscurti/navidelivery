require 'rails_helper'

RSpec.describe UserPolicy, type: :policy do
  subject { described_class }

  let(:account1) { create(:account) }
  let(:account2) { create(:account) }

  permissions '.scope' do
    let!(:super_admin) { create(:user, :super_admin) }
    let!(:admin_user) { create(:user, :admin, account: account1) }
    let!(:store_manager) { create(:user, :store_manager, account: account1) }
    let!(:regular_user) { create(:user, account: account1) }
    let!(:other_account_user) { create(:user, account: account2) }

    context 'for super_admin' do
      it 'returns all users' do
        expect(Pundit.policy_scope(super_admin, User)).to match_array([
          super_admin, admin_user, store_manager, regular_user, other_account_user
        ])
      end
    end

    context 'for admin' do
      it 'returns users from same account only' do
        expect(Pundit.policy_scope(admin_user, User)).to match_array([
          admin_user, store_manager, regular_user
        ])
      end
    end

    context 'for store_manager' do
      it 'returns non-admin users from same account' do
        expect(Pundit.policy_scope(store_manager, User)).to match_array([
          store_manager, regular_user
        ])
      end
    end

    context 'for regular user' do
      it 'returns only themselves' do
        expect(Pundit.policy_scope(regular_user, User)).to match_array([regular_user])
      end
    end
  end

  permissions :index? do
    it 'grants access to admin' do
      expect(subject).to permit(create(:user, :admin), User)
    end

    it 'grants access to super_admin' do
      expect(subject).to permit(create(:user, :super_admin), User)
    end

    it 'grants access to store_manager' do
      expect(subject).to permit(create(:user, :store_manager), User)
    end

    it 'denies access to regular user' do
      expect(subject).not_to permit(create(:user), User)
    end
  end

  permissions :show? do
    let(:user) { create(:user, account: account1) }
    let(:target_user) { create(:user, account: account1) }

    it 'grants access to super_admin for any user' do
      expect(subject).to permit(create(:user, :super_admin), target_user)
    end

    it 'grants access to admin for same account user' do
      admin = create(:user, :admin, account: account1)
      expect(subject).to permit(admin, target_user)
    end

    it 'denies access to admin for different account user' do
      admin = create(:user, :admin, account: account2)
      expect(subject).not_to permit(admin, target_user)
    end

    it 'grants access to user for themselves' do
      expect(subject).to permit(user, user)
    end

    it 'denies access to user for other users' do
      expect(subject).not_to permit(user, target_user)
    end
  end

  permissions :create? do
    it 'grants access to admin' do
      expect(subject).to permit(create(:user, :admin), User)
    end

    it 'grants access to super_admin' do
      expect(subject).to permit(create(:user, :super_admin), User)
    end

    it 'denies access to store_manager' do
      expect(subject).not_to permit(create(:user, :store_manager), User)
    end

    it 'denies access to regular user' do
      expect(subject).not_to permit(create(:user), User)
    end
  end

  permissions :update? do
    let(:target_user) { create(:user, account: account1) }

    it 'grants access to super_admin for any user' do
      expect(subject).to permit(create(:user, :super_admin), target_user)
    end

    it 'grants access to admin for same account user' do
      admin = create(:user, :admin, account: account1)
      expect(subject).to permit(admin, target_user)
    end

    it 'grants access to store_manager for non-admin same account user' do
      store_manager = create(:user, :store_manager, account: account1)
      expect(subject).to permit(store_manager, target_user)
    end

    it 'denies access to store_manager for admin user' do
      store_manager = create(:user, :store_manager, account: account1)
      admin_user = create(:user, :admin, account: account1)
      expect(subject).not_to permit(store_manager, admin_user)
    end

    it 'grants access to user for themselves' do
      expect(subject).to permit(target_user, target_user)
    end
  end

  permissions :destroy? do
    let(:target_user) { create(:user, account: account1) }
    let(:super_admin_user) { create(:user, :super_admin) }

    it 'denies access for super_admin target' do
      admin = create(:user, :admin, account: account1)
      expect(subject).not_to permit(admin, super_admin_user)
    end

    it 'grants access to super_admin for regular users' do
      expect(subject).to permit(super_admin_user, target_user)
    end

    it 'grants access to admin for non-admin same account user' do
      admin = create(:user, :admin, account: account1)
      expect(subject).to permit(admin, target_user)
    end

    it 'denies access to admin for other admin' do
      admin1 = create(:user, :admin, account: account1)
      admin2 = create(:user, :admin, account: account1)
      expect(subject).not_to permit(admin1, admin2)
    end
  end

  permissions :change_role? do
    let(:target_user) { create(:user, account: account1) }

    it 'grants access to super_admin' do
      expect(subject).to permit(create(:user, :super_admin), target_user)
    end

    it 'grants access to admin for non-admin same account user' do
      admin = create(:user, :admin, account: account1)
      expect(subject).to permit(admin, target_user)
    end

    it 'denies access to admin for admin user' do
      admin1 = create(:user, :admin, account: account1)
      admin2 = create(:user, :admin, account: account1)
      expect(subject).not_to permit(admin1, admin2)
    end

    it 'denies access to store_manager' do
      store_manager = create(:user, :store_manager, account: account1)
      expect(subject).not_to permit(store_manager, target_user)
    end
  end
end
