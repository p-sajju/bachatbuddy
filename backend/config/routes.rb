# frozen_string_literal: true

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "health", to: "health#show"
  get "ready", to: "health#ready"

  namespace :api do
    namespace :v1 do
      post "auth/signup", to: "auth#signup"
      post "auth/login", to: "auth#login"
      post "auth/logout", to: "auth#logout"
      post "auth/refresh", to: "auth#refresh"

      get "me", to: "me#show"
      patch "me", to: "me#update"
      put "me/avatar", to: "me#update_avatar"
      post "me/avatar", to: "me#update_avatar"
      delete "me/avatar", to: "me#destroy_avatar"

      resources :incomes
      resources :expenses
      resources :categories
      resources :payment_sources
      resources :people do
        member do
          get :summary
        end
      end
      resources :savings_goals do
        member do
          post :contribute
        end
      end
      resources :money_locks do
        member do
          post :unlock_preview
          post :unlock_request
          post :emergency_unlock
          post :confirm_unlock
          get :history
        end
      end
      resources :recurring_expenses
      resources :budgets

      get "dashboard", to: "dashboard#show"
      get "reports/monthly", to: "reports#monthly"
      get "reports/safe_to_spend", to: "reports#safe_to_spend"

      resources :notifications, only: %i[index show update] do
        collection do
          post :mark_all_read
        end
      end

      get "settings", to: "settings#show"
      patch "settings", to: "settings#update"
    end
  end
end
