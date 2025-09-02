module Dashboard
  class DeliveriesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_account

    def index
      @deliveries = @account.deliveries
                            .includes(:store, :courier)
                            .order(created_at: :desc)
                            .limit(500)
    end

    private

    def set_account
      @account = current_user.account
    end
  end
end
