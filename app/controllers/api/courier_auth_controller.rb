class Api::CourierAuthController < ApplicationController
  skip_before_action :verify_authenticity_token

  def login
    courier = Courier.find_by(phone: params[:phone])
    if courier && courier.authenticate(params[:password])
      token = JWT.encode({ courier_id: courier.id }, Rails.application.secrets.secret_key_base)
      render json: { token: token }
    else
      render json: { error: 'Invalid credentials' }, status: :unauthorized
    end
  end
end

