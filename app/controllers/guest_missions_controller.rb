# frozen_string_literal: true

# Handles the guest-facing mission interactions.
#
# GET    /guests/:guest_id/mission   → show active mission or empty state
# POST   /guests/:guest_id/mission   → auto-assign a new mission
# PATCH  /guests/:guest_id/mission   → change current mission (costs 1 attempt)
class GuestMissionsController < ApplicationController
  before_action :set_guest
  before_action :require_verification

  def show
    @assignment = @guest.active_assignment
    @mission    = @guest.current_mission
  end

  def create
    result = MissionAssignmentService.assign(@guest)

    if result.success?
      redirect_to guest_mission_path(@guest),
                  notice: "¡Misión asignada! Buena suerte."
    else
      redirect_to guest_mission_path(@guest),
                  alert: result.error
    end
  end

  def update
    result = MissionAssignmentService.change(@guest)

    if result.success?
      redirect_to guest_mission_path(@guest),
                  notice: "Misión cambiada. ¡A por ella!"
    else
      redirect_to guest_mission_path(@guest),
                  alert: result.error
    end
  end

  private

  def set_guest
    @guest = Guest.find(params[:guest_id])
  end

  def require_verification
    unless session[:verified_guest_id].to_i == @guest.id &&
           session[:verification_step].to_i >= 3
      redirect_to guest_verification_path(@guest, step: 1)
    end
  end
end
