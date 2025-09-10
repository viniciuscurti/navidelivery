class UserMailer < ApplicationMailer
  default from: ENV.fetch('DEFAULT_FROM_EMAIL', 'noreply@navidelivery.com')

  def welcome_email(user)
    @user = user
    @account = user.account
    @login_url = Rails.application.routes.url_helpers.new_user_session_url

    mail(
      to: @user.email,
      subject: "Bem-vindo ao NaviDelivery, #{@user.first_name}!"
    )
  end

  def password_reset_instructions(user, token)
    @user = user
    @token = token
    @reset_url = Rails.application.routes.url_helpers.edit_user_password_url(reset_password_token: @token)

    mail(
      to: @user.email,
      subject: 'Instruções para redefinir sua senha'
    )
  end

  def account_suspended(user)
    @user = user
    @support_email = ENV.fetch('SUPPORT_EMAIL', 'suporte@navidelivery.com')

    mail(
      to: @user.email,
      subject: 'Conta suspensa - NaviDelivery'
    )
  end

  def role_changed(user, old_role, new_role)
    @user = user
    @old_role = old_role
    @new_role = new_role

    mail(
      to: @user.email,
      subject: 'Sua função foi atualizada - NaviDelivery'
    )
  end
end
