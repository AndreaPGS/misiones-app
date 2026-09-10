# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Avoid blocking guests with older/unusual phones at a party
  # allow_browser versions: :modern

  # Ruby 4 + Rails 8.1 incompatibility: etag blocks registered by Turbo,
  # importmap-rails, and ActionController::EtagWithTemplateDigest use zero-arg
  # or one-arg blocks. Rails calls them via instance_exec(options, &block).
  # In Ruby 4, passing extra args to a fixed-arity block raises ArgumentError
  # on every request that sends If-None-Match (i.e. every repeat browser visit).
  #
  # This app has no need for HTTP caching via ETags, so we clear all etaggers.
  self.etaggers = []
  self.etag_with_template_digest = false

  # ── Global error handling ──────────────────────────────────────────────

  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActionController::ParameterMissing, with: :handle_bad_request

  private

  def handle_not_found
    redirect_to root_path, alert: "No encontramos lo que buscabas."
  end

  def handle_bad_request(exception)
    redirect_back_or_to root_path, alert: "Solicitud inválida: #{exception.message}"
  end
end
