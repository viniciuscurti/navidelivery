class Store < ApplicationRecord
  belongs_to :account
  has_many :deliveries

  # location: coluna geoespacial
end

