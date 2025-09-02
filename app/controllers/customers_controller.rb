class CustomersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_account

  def index
    @q = params[:q]
    @customers = Customer.for_account(@account.id).search(@q).order(created_at: :desc).limit(200)
  end

  def new
    @customer = @account.customers.build
  end

  def create
    @customer = @account.customers.build(customer_params)
    if @customer.save
      redirect_to @customer, notice: 'Cliente cadastrado com sucesso.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @customer = @account.customers.find(params[:id])
  end

  private

  def set_account
    @account = current_user.account
  end

  def customer_params
    params.require(:customer).permit(:name, :address, :zip_code, :phone)
  end
end
