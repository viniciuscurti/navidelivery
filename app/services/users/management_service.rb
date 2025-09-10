class Users::ManagementService
  include Interactor

  def call
    case context.action
    when :create
      create_user
    when :update
      update_user
    when :suspend
      suspend_user
    when :activate
      activate_user
    when :change_role
      change_role
    when :regenerate_token
      regenerate_token
    else
      context.fail!(error: "Unknown action: #{context.action}")
    end
  end

  private

  def create_user
    user = User.new(context.user_params)
    user.account = context.account if context.account

    if user.save
      context.user = user
      UserMailer.welcome_email(user).deliver_later
    else
      context.fail!(errors: user.errors.full_messages)
    end
  end

  def update_user
    user = context.user
    old_role = user.role

    if user.update(context.user_params)
      context.user = user

      # Send email if role changed
      if old_role != user.role
        UserMailer.role_changed(user, old_role, user.role).deliver_later
      end
    else
      context.fail!(errors: user.errors.full_messages)
    end
  end

  def suspend_user
    user = context.user

    if user.update(status: :suspended)
      context.user = user
      UserMailer.account_suspended(user).deliver_later
    else
      context.fail!(errors: user.errors.full_messages)
    end
  end

  def activate_user
    user = context.user

    if user.update(status: :active)
      context.user = user
    else
      context.fail!(errors: user.errors.full_messages)
    end
  end

  def change_role
    user = context.user
    old_role = user.role
    new_role = context.new_role

    if user.update(role: new_role)
      context.user = user
      UserMailer.role_changed(user, old_role, new_role).deliver_later
    else
      context.fail!(errors: user.errors.full_messages)
    end
  end

  def regenerate_token
    user = context.user

    begin
      user.regenerate_api_token!
      context.user = user
    rescue => e
      context.fail!(error: e.message)
    end
  end
end
