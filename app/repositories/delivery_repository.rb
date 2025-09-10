class DeliveryRepository
  def self.find_by_public_token(token)
    Delivery.find_by(public_token: token)
  end

  def self.for_account(account)
    account.deliveries
  end

  def self.active_for_courier(courier_id)
    Delivery.in_progress.where(courier_id: courier_id)
  end
end
