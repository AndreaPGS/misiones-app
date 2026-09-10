# frozen_string_literal: true

class Admin::DashboardController < Admin::ApplicationController
  def index
    @total_guests      = Guest.count
    @total_missions    = Mission.count
    @active_missions   = Mission.active.count
    @total_assignments = MissionAssignment.count
    @assigned_count    = MissionAssignment.assigned.count
    @completed_count   = MissionAssignment.completed.count
    @abandoned_count   = MissionAssignment.abandoned.count
    @top_guests        = Guest.order(points: :desc, name: :asc).limit(3)
  end
end
