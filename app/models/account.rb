class Account < ApplicationRecord
  has_many :stores
  has_many :users
  has_many :couriers
  has_many :deliveries
  has_many :subscriptions
  has_many :webhook_endpoints
end

