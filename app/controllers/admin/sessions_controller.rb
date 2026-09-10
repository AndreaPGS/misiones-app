# frozen_string_literal: true

# Handles admin login/logout via secret word.
# Intentionally not an API — renders a form and redirects.
class Admin::SessionsController < ApplicationController
  layout "admin"
  # Skip the admin guard — this IS the gate
  def new
    redirect_to admin_root_path if session[:admin_authenticated]
  end

  def create
    if params[:password] == Admin::ApplicationController::ADMIN_PASSWORD
      session[:admin_authenticated] = true
      redirect_to admin_root_path, notice: "Bienvenido, administrador."
    else
      flash.now[:alert] = "Palabra secreta incorrecta."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:admin_authenticated)
    redirect_to admin_login_path, notice: "Sesión cerrada."
  end
end
