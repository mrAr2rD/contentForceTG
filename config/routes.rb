Rails.application.routes.draw do
  # Health check
  get '/health', to: 'health#index'

  # Devise routes with custom controllers
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  # Authenticated root - Dashboard
  authenticated :user do
    root 'dashboard#index', as: :authenticated_root
  end

  # Public root - Landing page
  root 'pages#home'

  # Dashboard
  get 'dashboard', to: 'dashboard#index', as: :dashboard

  # Calendar
  get 'calendar', to: 'calendar#index', as: :calendar

  # Analytics
  get 'analytics', to: 'analytics#index', as: :analytics  # Posts (must be defined before projects for correct route priority)
  resources :posts do
    collection do
      get :editor
    end

    member do
      post :publish
      post :schedule
    end
  end

  # Projects
  resources :projects do
    member do
      post :archive
      post :activate
    end

    # Nested resources
    resources :telegram_bots do
      member do
        post :verify
      end
    end

    # Nested posts (only new/create, other actions use top-level routes)
    resources :posts, only: [:new, :create]
  end

  # API namespace
  namespace :api do
    namespace :v1 do
      resources :ai, only: [] do
        collection do
          post :generate
          post :improve
          post :generate_hashtags
        end
      end

      # Posts API
      resources :posts, only: [:index, :show, :create, :update, :destroy]
      
      # Projects API  
      resources :projects, only: [:index, :show]
    end
  end

  # Webhooks
  namespace :webhooks do
    post 'telegram/:bot_token', to: 'telegram#receive', as: :telegram
  end

  # Static pages
  get 'pages/home'
  
  # Admin namespace - Simple admin without Administrate
  namespace :admin do
    get '/', to: 'dashboard#index'
    resources :users, only: [:index, :show, :edit, :update, :destroy]
    resources :projects, only: [:index, :show, :destroy]
    resources :posts, only: [:index, :show, :destroy]
    resources :telegram_bots, only: [:index, :show, :destroy]
    resources :subscriptions

    # AI Settings (singleton resource)
    resource :ai_settings, only: [:edit, :update]

    root to: "users#index"
  end
  
  # Rails health check
  get 'up' => 'rails/health#show', as: :rails_health_check
end
