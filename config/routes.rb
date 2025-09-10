Rails.application.routes.draw do
  devise_for :users, path: 'auth'

  # Health check
  get '/health', to: 'health#show'

  # Landing page routes
  root 'home#index'
  get '/demo', to: 'home#demo'
  get '/pricing', to: 'home#pricing'
  get '/contact', to: 'home#contact'
  get '/about', to: 'home#about'

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

      # Google Maps integration
      namespace :maps do
        post :geocode
        post :validate_address
        post :calculate_route
        post :update_eta
        post :optimize_route
        get :calculate_distance, to: 'maps#calculate_distance'
      end

      # Webhooks
      resources :webhook_endpoints, only: [:create, :update, :destroy]

      # API pública para tracking em tempo real
      namespace :public do
        # Rotas de tracking público (sem autenticação)
        get 'track/:token', to: 'tracking#show'
        get 'track/:token/route', to: 'tracking#route'
        get 'track/:token/timeline', to: 'tracking#timeline'
        post 'track/:token/location', to: 'tracking#location_update'
        post 'track/:token/subscribe', to: 'tracking#subscribe_updates'

        # Rotas antigas mantidas para compatibilidade
        get 'deliveries/:token', to: 'public#delivery'
        get 'deliveries/:token/status', to: 'public#delivery_status'
      end

      # Rota para página visual de tracking
      get 'track/:token', to: 'public/tracking_view#show', as: :public_tracking_page
    end
  end

  # WebSocket
  mount ActionCable.server => '/cable'

  # Sidekiq Web UI (development only)
  if Rails.env.development?
    require 'sidekiq/web'
    mount Sidekiq::Web => '/sidekiq'
  end
end
