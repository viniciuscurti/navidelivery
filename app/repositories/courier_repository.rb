class CourierRepository
  def self.for_account(account)
    account.couriers
  end

  def self.find_by_id(account, id)
    account.couriers.find(id)
  end
end

