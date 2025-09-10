class UserPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      case user.role
      when 'super_admin'
        scope.all
      when 'admin'
        scope.by_account(user.account)
      when 'store_manager'
        scope.by_account(user.account).where.not(role: ['admin', 'super_admin'])
      else
        scope.where(id: user.id)
      end
    end
  end

  def index?
    user.admin? || user.super_admin? || user.store_manager?
  end

  def show?
    user.super_admin? ||
    user.can_manage_account?(record.account) ||
    user.id == record.id
  end

  def create?
    user.admin? || user.super_admin?
  end

  def update?
    return true if user.super_admin?
    return true if user.admin? && same_account?
    return true if user.store_manager? && same_account? && !record.admin? && !record.super_admin?

    user.id == record.id && limited_self_update?
  end

  def destroy?
    return false if record.super_admin?
    return true if user.super_admin?
    return true if user.admin? && same_account? && !record.admin?

    false
  end

  def activate?
    can_change_status?
  end

  def suspend?
    can_change_status? && !record.super_admin?
  end

  def change_role?
    return true if user.super_admin?
    return true if user.admin? && same_account? && !record.admin? && !record.super_admin?

    false
  end

  def regenerate_api_token?
    update?
  end

  private

  def same_account?
    user.account == record.account
  end

  def can_change_status?
    return true if user.super_admin?
    return true if user.admin? && same_account?

    false
  end

  def limited_self_update?
    # Users can only update their own basic info, not role or status
    true
  end
end
