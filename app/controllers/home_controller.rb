class HomeController < ApplicationController
  def index
  end

  def admin
    authenticate_user!
  end
end

