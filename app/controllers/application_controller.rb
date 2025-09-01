class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include PaperTrail::Rails::Controller

  before_action :authenticate_user!, if: :authentication_required?
  before_action :set_paper_trail_whodunnit

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def after_sign_in_path_for(_resource)
    admin_path
  end

  private

  def user_not_authorized
    respond_to do |format|
      format.html { redirect_to(request.referrer || root_path, alert: 'Acesso não autorizado.') }
      format.json { render json: { error: 'not_authorized' }, status: :forbidden }
    end
  end

  # Evita exigir login em páginas públicas (ex: tracking) e devise controllers
  def authentication_required?
    return false if devise_controller?
    !public_path?
  end

  def public_path?
    request.path.start_with?('/public/track') || request.path == '/'
  end
end
