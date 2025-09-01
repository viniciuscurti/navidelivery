class Account < ApplicationRecord
  has_many :stores, dependent: :destroy
  has_many :users, dependent: :destroy
  has_many :couriers, dependent: :destroy
  has_many :deliveries, through: :stores
  has_many :webhook_endpoints, dependent: :destroy
  has_one :subscription, dependent: :destroy

  validates :name, presence: true
  validates :status, inclusion: { in: %w[active suspended canceled] }

  enum status: { active: 0, suspended: 1, canceled: 2 }

  def active_deliveries_count
    deliveries.active.count
  end

  def monthly_deliveries_count
    deliveries.where(created_at: 1.month.ago..Time.current).count
  end

  def within_limits?
    return true unless subscription

    monthly_deliveries_count <= subscription.delivery_limit &&
      couriers.active.count <= subscription.courier_limit
  end
end
