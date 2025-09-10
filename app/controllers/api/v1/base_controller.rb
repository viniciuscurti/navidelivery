class Api::V1::BaseController < ApplicationController
  include Pundit::Authorization

  protect_from_forgery with: :null_session
  before_action :authenticate_api_user!
  before_action :set_current_account

  rescue_from Pundit::NotAuthorizedError, with: :forbidden_response
  rescue_from ActiveRecord::RecordNotFound, with: :not_found_response
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity_response
  rescue_from StandardError, with: :internal_server_error_response

  private

  def authenticate_api_user!
    token = request.headers['Authorization']&.split(' ')&.last
    return unauthorized_response unless token

    begin
      decoded = JWT.decode(token, Rails.application.credentials.jwt_secret, true, { algorithm: 'HS256' })
      @current_user = User.find(decoded[0]['user_id'])
    rescue JWT::DecodeError, JWT::ExpiredSignature, ActiveRecord::RecordNotFound
      unauthorized_response
    end
  end

  def current_user
    @current_user
  end

  def set_current_account
    @current_account = current_user&.account
  end

  def current_account
    @current_account
  end

  # Response helpers
  def success_response(data = {}, status = :ok)
    render json: {
      success: true,
      data: data,
      timestamp: Time.current.iso8601
    }, status: status
  end

  def error_response(message, status = :bad_request, errors = [])
    render json: {
      success: false,
      message: message,
      errors: errors,
      timestamp: Time.current.iso8601
    }, status: status
  end

  def unauthorized_response
    error_response('Unauthorized', :unauthorized)
  end

  def forbidden_response
    error_response('Forbidden', :forbidden)
  end

  def not_found_response
    error_response('Resource not found', :not_found)
  end

  def unprocessable_entity_response(exception)
    error_response('Validation failed', :unprocessable_entity, exception.record.errors.full_messages)
  end

  def internal_server_error_response(exception)
    Rails.logger.error "API Error: #{exception.message}\n#{exception.backtrace.join("\n")}"

    if Rails.env.production?
      error_response('Internal server error', :internal_server_error)
    else
      error_response(exception.message, :internal_server_error, [exception.backtrace.first(5)])
    end
  end
end
