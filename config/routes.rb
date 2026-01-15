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
    
    resources :posts, shallow: true
  end

  # Posts (top-level access)
  get 'posts/editor', to: 'posts#editor'
  resources :posts do
    member do
      post :publish
      post :schedule
    end
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
  
  # Admin namespace
  namespace :admin do
    resources :users
    resources :projects
    resources :posts
    resources :telegram_bots
    resources :subscriptions

    root to: "users#index"
  end
  
  # Rails health check
  get 'up' => 'rails/health#show', as: :rails_health_check
end
