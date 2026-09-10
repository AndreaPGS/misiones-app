# frozen_string_literal: true

module AdminHelper
  # Returns CSS class "admin-nav__item--active" when the current path matches.
  # exact: true → only match the exact path (useful for root)
  def active_nav?(path, exact: false)
    current = request.path
    if exact
      current == path ? "admin-nav__item--active" : ""
    else
      current.start_with?(path) ? "admin-nav__item--active" : ""
    end
  end

  # Human-readable label + color class for assignment status
  def status_label(status)
    case status.to_s
    when "assigned"  then "Activa"
    when "completed" then "Completada"
    when "abandoned" then "Abandonada"
    else status.to_s.capitalize
    end
  end

  def status_chip_class(status)
    "status-chip status-chip--#{status}"
  end
end
