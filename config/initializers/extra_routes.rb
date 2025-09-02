Rails.application.config.after_initialize do
  Rails.application.routes.append do
    resources :customers, only: [:index, :new, :create, :show]

    namespace :dashboard do
      resources :deliveries, only: [:index]
    end
  end
end
