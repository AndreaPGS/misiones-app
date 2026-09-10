# frozen_string_literal: true

class Admin::GuestsController < Admin::ApplicationController
  before_action :set_guest, only: [ :show, :edit, :update, :destroy ]

  def index
    @guests = Guest.order(:name)
  end

  def show
    @assignments = @guest.mission_assignments
                         .includes(:mission)
                         .order(assigned_at: :desc)
  end

  def new
    @guest = Guest.new
  end

  def create
    @guest = Guest.new(guest_params)

    if @guest.save
      redirect_to admin_guest_path(@guest), notice: "Invitado creado correctamente."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @guest.update(guest_params)
      redirect_to admin_guest_path(@guest), notice: "Invitado actualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @guest.destroy
    redirect_to admin_guests_path, notice: "Invitado eliminado.", status: :see_other
  end

  private

  def set_guest
    @guest = Guest.find(params[:id])
  end

  def guest_params
    params.expect(guest: [ :name, :phone, :email, :picture, :points, :attempts ])
  end
end
