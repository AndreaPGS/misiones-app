Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # ── Public flow ──────────────────────────────────────────────────────────

  root "guests#index"

  resources :guests, only: [ :index, :show ] do
    # Verification flow: 3-step social barrier before accessing the profile
    # GET  /guests/:guest_id/verification        → show current step
    # POST /guests/:guest_id/verification        → advance step
    resource :verification, only: [ :show, :create ],
                            controller: "verifications"

    # Guest mission: view, auto-assign, change
    # GET    /guests/:guest_id/mission            → show active mission (or empty state)
    # POST   /guests/:guest_id/mission            → auto-assign a mission
    # PATCH  /guests/:guest_id/mission            → change current mission
    resource :mission, only: [ :show, :create, :update ],
                       controller: "guest_missions"
  end

  # ── Admin ─────────────────────────────────────────────────────────────────

  # Login / logout live outside the namespace so /admin/login is the gate
  get    "/admin/login",  to: "admin/sessions#new",     as: :admin_login
  post   "/admin/login",  to: "admin/sessions#create",  as: :admin_session
  delete "/admin/logout", to: "admin/sessions#destroy", as: :admin_logout

  namespace :admin do
    root "dashboard#index"

    resources :guests

    resources :missions

    resources :mission_assignments do
      member do
        patch :complete   # PATCH /admin/mission_assignments/:id/complete
      end
    end

    get "ranking", to: "ranking#index", as: :ranking
  end
end
