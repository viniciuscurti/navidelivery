class Api::V1::BaseController < ApplicationController
  include MobileOptimized

  protect_from_forgery with: :null_session
  before_action :authenticate_api_user!
  before_action :set_current_account

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
  rescue_from Pundit::NotAuthorizedError, with: :forbidden

  private

  def authenticate_api_user!
    token = request.headers['Authorization']&.split(' ')&.last
    @current_user = User.find_by(api_token: token) if token

    render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_user
  end

  def set_current_account
    @current_account = @current_user&.account
  end

  def current_account
    @current_account
  end

  def not_found
    render json: { error: 'Not found' }, status: :not_found
  end

  def unprocessable_entity(exception)
    render json: {
      error: 'Validation failed',
      details: exception.record.errors.full_messages
    }, status: :unprocessable_entity
  end

  def forbidden
    render json: { error: 'Access denied' }, status: :forbidden
  end
end

