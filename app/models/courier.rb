class Courier < ApplicationRecord
  belongs_to :account
  has_many :deliveries, dependent: :nullify
  has_many :location_pings, dependent: :destroy
  has_paper_trail

  validates :name, presence: true
end

