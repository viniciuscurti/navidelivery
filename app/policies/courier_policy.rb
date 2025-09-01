class CourierPolicy < ApplicationPolicy
  def index?; user.present?; end
  def show?; owner_account?; end
  def create?; user.present?; end
  def update?; owner_account?; end
  def destroy?; owner_account?; end

  class Scope < Scope
    def resolve
      return scope.none unless user
      scope.where(account_id: user.account_id)
    end
  end
end

