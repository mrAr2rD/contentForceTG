require_relative '../lib/constraints/subdomain_constraint'

Rails.application.routes.draw do
  # Мини-сайты каналов (subdomain/custom domain routing)
  constraints SubdomainConstraint.new do
    get '/', to: 'channel_sites#show', as: :channel_site_root
    get '/posts', to: 'channel_sites#posts', as: :channel_site_posts
    get '/post/:slug', to: 'channel_sites#post', as: :channel_site_post
    get '/sitemap.xml', to: 'channel_sites#sitemap', as: :channel_site_sitemap, defaults: { format: :xml }
  end

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

  # Channel Sites (мини-сайты)
  namespace :dashboard do
    resources :channel_sites do
      member do
        post :enable
        post :disable
        post :sync
        post :verify_domain
      end
      resources :channel_posts, only: [:index, :show, :edit, :update]
    end
  end

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
        get :subscriber_analytics
      end

      resources :invite_links, only: [:index, :new, :create, :destroy]
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
          post :generate_image
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
    post 'channel_sync', to: 'channel_sync#receive', as: :channel_sync
  end

  # Static pages
  get 'pages/home'
  get 'terms', to: 'pages#terms', as: :terms
  get 'privacy', to: 'pages#privacy', as: :privacy
  get 'about', to: 'pages#about', as: :about
  get 'careers', to: 'pages#careers', as: :careers
  get 'contacts', to: 'pages#contacts', as: :contacts
  post 'contacts', to: 'pages#submit_contact', as: :submit_contact
  get 'docs', to: 'pages#docs', as: :docs

  # Blog
  get 'blog', to: 'articles#index', as: :blog
  resources :articles, only: [:index, :show], param: :slug

  # Admin namespace - Simple admin without Administrate
  namespace :admin do
    root to: "dashboard#index"

    resources :users, only: [:index, :show, :edit, :update, :destroy]
    resources :projects, only: [:index, :show, :destroy]
    resources :posts, only: [:index, :show, :destroy]
    resources :telegram_bots, only: [:index, :show, :destroy]
    resources :subscriptions
    # AI Settings (singleton resource)
    resource :ai_settings, only: [:edit, :update]

    # Payment Settings (Robokassa)
    resource :payment_settings, only: [:edit, :update]

    # Тарифные планы
    resources :plans

    # AI модели с ценами
    resources :ai_models do
      member do
        patch :toggle_active
      end
      collection do
        post :sync_defaults
      end
    end

    # Пригласительные ссылки
    resources :invite_links, only: [:index, :show, :destroy]

    # Логи AI
    resources :ai_usage_logs, only: [:index]

    # Уведомления
    resources :notifications, only: [:index, :show]

    # Платежи с возвратом
    resources :payments, only: [:index, :show] do
      member do
        post :refund
      end
    end

    # ROI дашборд
    get 'roi', to: 'roi#index'

    # Шаблоны уведомлений
    resources :notification_templates do
      collection do
        post :load_defaults
      end
    end

    # Статьи блога
    resources :articles do
      member do
        get :preview
        post :generate_content
      end
      collection do
        post :generate_content
      end
    end
  end
  
  # Rails health check
  get 'up' => 'rails/health#show', as: :rails_health_check
end
