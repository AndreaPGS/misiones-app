# frozen_string_literal: true

class Admin::ApplicationController < ApplicationController
  ADMIN_PASSWORD = "kikito"

  layout "admin"
  helper AdminHelper

  before_action :require_admin

  private

  def require_admin
    unless session[:admin_authenticated]
      redirect_to admin_login_path, alert: "Acceso restringido."
    end
  end

  def current_admin?
    session[:admin_authenticated] == true
  end
  helper_method :current_admin?
end
