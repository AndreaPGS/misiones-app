# frozen_string_literal: true

class GuestsController < ApplicationController
  def index
    @guests = Guest.order(:name)
  end

  def show
    @guest = Guest.find(params[:id])

    # Redirect to verification flow if the guest hasn't been verified this session.
    # Verification stores { verified_guest_id: id, verification_step: 3 } in the session.
    unless verified_as?(@guest)
      redirect_to guest_verification_path(@guest, step: 1) and return
    end

    @active_assignment = @guest.active_assignment
    @current_mission   = @guest.current_mission
    @history           = @guest.mission_assignments
                               .includes(:mission)
                               .order(assigned_at: :desc)
  end

  private

  def verified_as?(guest)
    session[:verified_guest_id].to_i == guest.id &&
      session[:verification_step].to_i >= 3
  end
end
