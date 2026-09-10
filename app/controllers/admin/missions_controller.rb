# frozen_string_literal: true

class Admin::MissionsController < Admin::ApplicationController
  before_action :set_mission, only: [ :show, :edit, :update, :destroy ]

  def index
    @missions = Mission.includes(:target).order(:description)
  end

  def show
    @restricted_guests = @mission.restricted_guests.order(:name)
    @target_guests     = @mission.target_guests.order(:name)
    @assignments       = @mission.mission_assignments
                                 .includes(:guest)
                                 .order(assigned_at: :desc)
  end

  def new
    @mission = Mission.new
    load_guests
  end

  def create
    @mission = Mission.new(mission_scalar_params)

    if @mission.save
      sync_habtm_relations
      redirect_to admin_mission_path(@mission), notice: "Misión creada correctamente."
    else
      load_guests
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_guests
  end

  def update
    if @mission.update(mission_scalar_params)
      sync_habtm_relations
      redirect_to admin_mission_path(@mission), notice: "Misión actualizada."
    else
      load_guests
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @mission.destroy
    redirect_to admin_missions_path, notice: "Misión eliminada.", status: :see_other
  end

  private

  def set_mission
    @mission = Mission.find(params[:id])
  end

  def load_guests
    @all_guests = Guest.order(:name)
  end

  # Scalar fields only — HABTM arrays are handled separately in sync_habtm_relations
  # because permit() treats [] differently from scalar values.
  def mission_scalar_params
    params.require(:mission).permit(:description, :score, :active, :target_id)
  end

  # Replace HABTM collections from permitted array params.
  # We use permit(ids: []) so Strong Parameters allows the arrays,
  # then assign the resulting Guest collections directly.
  def sync_habtm_relations
    mission_array_params = params.require(:mission).permit(
      restricted_guest_ids: [],
      target_guest_ids: []
    )

    @mission.restricted_guests = Guest.where(
      id: Array(mission_array_params[:restricted_guest_ids]).reject(&:blank?)
    )

    @mission.target_guests = Guest.where(
      id: Array(mission_array_params[:target_guest_ids]).reject(&:blank?)
    )
  end
end
