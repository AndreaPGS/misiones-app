# frozen_string_literal: true

# Value object returned by every service operation.
# Avoids raising exceptions for expected business-rule failures
# and keeps controllers thin.
#
# Usage:
#   result = MissionAssignmentService.new(guest).assign
#   if result.success?
#     redirect_to guest_path(result.payload)
#   else
#     flash[:alert] = result.error
#   end
class ServiceResult
  attr_reader :payload, :error

  def initialize(success:, payload: nil, error: nil)
    @success = success
    @payload = payload
    @error   = error
  end

  def success? = @success
  def failure? = !@success

  # Convenience constructors
  def self.ok(payload = nil)
    new(success: true, payload: payload)
  end

  def self.fail(error, payload: nil)
    new(success: false, error: error, payload: payload)
  end
end
