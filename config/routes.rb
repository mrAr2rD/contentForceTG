Rails.application.routes.draw do
  # Health check
  get '/health', to: 'health#index'

  # Devise routes with custom controllers
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    registrations: 'users/registrations'
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
      delete :remove_image
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

  # Subscriptions
  resources :subscriptions, only: [:index] do
    collection do
      post :upgrade
      post :downgrade
      post :cancel
    end
  end

  # Webhooks
  namespace :webhooks do
    post 'telegram/:bot_token', to: 'telegram#receive', as: :telegram
    post 'robokassa/result', to: 'robokassa#result', as: :robokassa_result
    get 'robokassa/success', to: 'robokassa#success', as: :robokassa_success
    get 'robokassa/fail', to: 'robokassa#fail', as: :robokassa_fail
  end

  # Static pages
  get 'pages/home'
  get 'terms', to: 'pages#terms', as: :terms
  get 'privacy', to: 'pages#privacy', as: :privacy

  # Admin namespace - Simple admin without Administrate
  namespace :admin do
    root to: "dashboard#index"

    resources :users, only: [:index, :show, :edit, :update, :destroy]
    resources :projects, only: [:index, :show, :destroy]
    resources :posts, only: [:index, :show, :destroy]
    resources :telegram_bots, only: [:index, :show, :destroy]
    resources :subscriptions
    resources :payments, only: [:index, :show]

    # AI Settings (singleton resource)
    resource :ai_settings, only: [:edit, :update]

    # Payment Settings (Robokassa)
    resource :payment_settings, only: [:edit, :update]
  end
  
  # Rails health check
  get 'up' => 'rails/health#show', as: :rails_health_check
end
