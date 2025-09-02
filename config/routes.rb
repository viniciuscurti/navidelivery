Rails.application.routes.draw do
  devise_for :users, path: 'auth'

  # Health check
  get '/health', to: 'health#show'

  # Admin portal
  namespace :admin do
    root 'dashboard#index'
    resources :accounts do
      resources :stores
      resources :couriers
      resources :deliveries do
        member do
          post :assign
          patch :update_status
        end
      end
    end
    resources :users
  end

  # API
  namespace :api do
    namespace :v1 do
      resources :deliveries, only: [:create, :show, :update] do
        member do
          post :assign
          post :pings
          get :status
        end
      end
      resources :couriers, only: [:index, :show] do
        member do
          post :start_shift
          post :end_shift
        end
      end

      # Webhooks
      resources :webhook_endpoints, only: [:create, :update, :destroy]

      # API pública para tracking
      namespace :public do
        get 'deliveries/:token', to: 'public#delivery'
        get 'deliveries/:token/status', to: 'public#delivery_status'
      end

      # Novas rotas públicas de tracking (sem auth)
      get '/deliveries/track/:token', to: 'tracking#show'
      get '/deliveries/track/:token/status', to: 'tracking#status'
    end
  end

  # WebSocket
  mount ActionCable.server => '/cable'

  # Sidekiq Web UI (development only)
  if Rails.env.development?
    require 'sidekiq/web'
    mount Sidekiq::Web => '/sidekiq'
  end

  root 'admin/dashboard#index'
end
