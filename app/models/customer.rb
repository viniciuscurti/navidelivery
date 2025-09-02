class Customer < ApplicationRecord
  belongs_to :account

  validates :name, presence: true, length: { maximum: 120 }
  validates :address, presence: true, length: { maximum: 255 }
  validates :zip_code, presence: true, length: { maximum: 20 }
  validates :phone, presence: true, length: { maximum: 30 }

  scope :for_account, ->(account_id) { where(account_id: account_id) }
  scope :search, ->(q) {
    return all if q.blank?
    where("unaccent(name) ILIKE unaccent(:q) OR unaccent(address) ILIKE unaccent(:q) OR phone ILIKE :q", q: "%#{q}%")
  }
end
