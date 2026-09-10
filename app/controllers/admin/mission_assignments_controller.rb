# frozen_string_literal: true

class Admin::MissionAssignmentsController < Admin::ApplicationController
  before_action :set_assignment, only: [ :show, :edit, :update, :destroy, :complete ]

  def index
    @assignments = MissionAssignment
      .includes(:guest, :mission)
      .then { |scope| filter_by_status(scope) }
      .order(assigned_at: :desc)

    @status_filter = params[:status]
  end

  def show; end

  def new
    @assignment = MissionAssignment.new
    load_form_data
  end

  # Admin creates an assignment via the service so all business rules apply
  # (active mission, guest not in restricted_guests, no active duplicate).
  def create
    guest   = Guest.find(assignment_create_params[:guest_id])
    mission = Mission.find(assignment_create_params[:mission_id])

    result = MissionAssignmentService.assign_manual(guest, mission)

    if result.success?
      redirect_to admin_mission_assignment_path(result.payload),
                  notice: "Asignación creada correctamente."
    else
      @assignment = MissionAssignment.new(assignment_create_params)
      load_form_data
      flash.now[:alert] = result.error
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_form_data
  end

  # Edit allows correcting timestamps only.
  # Status changes MUST go through the dedicated actions (complete, etc.)
  # to keep points consistent. Allowing free status edits would bypass
  # MissionAssignmentService#complete and leave points out of sync.
  def update
    if @assignment.update(assignment_update_params)
      redirect_to admin_mission_assignment_path(@assignment),
                  notice: "Asignación actualizada."
    else
      load_form_data
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @assignment.destroy
    redirect_to admin_mission_assignments_path,
                notice: "Asignación eliminada.", status: :see_other
  end

  # PATCH /admin/mission_assignments/:id/complete
  # The only correct way to mark a mission done and award points.
  def complete
    result = MissionAssignmentService.complete(@assignment)

    if result.success?
      redirect_to admin_mission_assignment_path(@assignment),
                  notice: "¡Misión confirmada! Se sumaron #{@assignment.mission.score} puntos."
    else
      redirect_to admin_mission_assignment_path(@assignment),
                  alert: result.error
    end
  end

  private

  def set_assignment
    @assignment = MissionAssignment.includes(:guest, :mission).find(params[:id])
  end

  def load_form_data
    @guests   = Guest.order(:name)
    @missions = Mission.order(:description)
  end

  # Used only for new assignment creation — guest_id and mission_id only.
  # The service handles everything else.
  def assignment_create_params
    params.require(:mission_assignment).permit(:guest_id, :mission_id)
  end

  # Status is intentionally excluded — use #complete action to change status.
  def assignment_update_params
    params.require(:mission_assignment).permit(:assigned_at, :completed_at)
  end

  def filter_by_status(scope)
    return scope unless params[:status].present? &&
                        MissionAssignment.statuses.key?(params[:status])

    scope.where(status: params[:status])
  end
end
