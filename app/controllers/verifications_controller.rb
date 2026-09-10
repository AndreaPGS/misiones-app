# frozen_string_literal: true

# Handles the 3-step social verification barrier.
#
# This is NOT authentication. It's a fun social friction layer to prevent
# accidental impersonation. State is kept in the Rails session.
#
# GET  /guests/:guest_id/verification?step=N  → renders the step screen
# POST /guests/:guest_id/verification         → advances the step
#
# Session keys used:
#   :verified_guest_id   → id of the guest being verified
#   :verification_step   → current step (1, 2, 3). Access granted at step >= 3.
class VerificationsController < ApplicationController
  TOTAL_STEPS = 3

  before_action :set_guest

  def show
    # Reset verification state if a different guest is being verified
    if session[:verified_guest_id].to_i != @guest.id
      reset_verification
    end

    @step = current_step
  end

  def create
    # Reset if switching to a different guest mid-flow
    if session[:verified_guest_id].to_i != @guest.id
      reset_verification
    end

    next_step = current_step + 1

    if next_step > TOTAL_STEPS
      # All steps passed — mark as fully verified and go to the profile
      session[:verified_guest_id] = @guest.id
      session[:verification_step] = TOTAL_STEPS
      redirect_to guest_path(@guest)
    else
      session[:verified_guest_id] = @guest.id
      session[:verification_step] = next_step
      redirect_to guest_verification_path(@guest, step: next_step)
    end
  end

  private

  def set_guest
    @guest = Guest.find(params[:guest_id])
  end

  def current_step
    # Use the step from session if it belongs to this guest, otherwise start at 1
    if session[:verified_guest_id].to_i == @guest.id
      session[:verification_step].to_i.clamp(1, TOTAL_STEPS)
    else
      1
    end
  end

  def reset_verification
    session[:verified_guest_id] = @guest.id
    session[:verification_step] = 1
  end
end
