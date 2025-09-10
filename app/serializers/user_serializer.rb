class UserSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id, :email, :first_name, :last_name, :phone, :role, :status, :created_at, :updated_at

  attribute :full_name do |user|
    user.full_name
  end

  attribute :initials do |user|
    user.initials
  end

  attribute :active do |user|
    user.active?
  end

  belongs_to :account, serializer: AccountSerializer, if: proc { |record| record.account.present? }

  # Conditional attributes based on permissions
  attribute :api_token, if: proc { |record, params|
    current_user = params[:current_user]
    current_user&.id == record.id || current_user&.can_manage_account?(record.account)
  }

  attribute :last_sign_in_at, if: proc { |record, params|
    current_user = params[:current_user]
    current_user&.admin? || current_user&.super_admin? || current_user&.id == record.id
  }

  attribute :permissions do |user, params|
    current_user = params[:current_user]
    next {} unless current_user

    {
      can_edit: UserPolicy.new(current_user, user).update?,
      can_delete: UserPolicy.new(current_user, user).destroy?,
      can_change_role: UserPolicy.new(current_user, user).change_role?,
      can_suspend: UserPolicy.new(current_user, user).suspend?
    }
  end
end
