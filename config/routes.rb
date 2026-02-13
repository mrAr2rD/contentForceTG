Rails.application.routes.draw do
  # Мини-сайты каналов (subdomain/custom domain routing)
  constraints SubdomainConstraint.new do
    get "/", to: "channel_sites#show", as: :channel_site_root
    get "/posts", to: "channel_sites#posts", as: :channel_site_posts
    get "/post/:slug", to: "channel_sites#post", as: :channel_site_post
    get "/sitemap.xml", to: "channel_sites#sitemap", as: :channel_site_sitemap, defaults: { format: :xml }
  end

  # Health check
  get "/health", to: "health#index"

  # Security endpoints
  post "/csp-violation-report-endpoint", to: "security#csp_report"

  # Devise routes with custom controllers
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks",
    registrations: "users/registrations"
  }

  # Authenticated root - Dashboard
  authenticated :user do
    root "dashboard#index", as: :authenticated_root
  end

  # Public root - Landing page
  root "pages#home"

  # Onboarding (4-step wizard for new users)
  resource :onboarding, only: [ :show ], controller: "onboarding" do
    post :update_step
    post :skip
  end

  # Dashboard
  get "dashboard", to: "dashboard#index", as: :dashboard

  # Calendar
  get "calendar", to: "calendar#index", as: :calendar

  # Channel Sites (мини-сайты)
  namespace :dashboard do
    resources :channel_sites do
      member do
        post :enable
        post :disable
        post :sync
        post :verify_domain
      end
      resources :channel_posts, only: [ :index, :show, :edit, :update ] do
        collection do
          patch :bulk_update
        end
      end
    end
  end

  # Analytics
  get "analytics", to: "analytics#index", as: :analytics
  post "analytics/refresh_stats", to: "analytics#refresh_stats", as: :refresh_analytics_stats

  # Posts (must be defined before projects for correct route priority)
  resources :posts do
    collection do
      get :editor
    end

    member do
      post :publish
      post :schedule
      post :refresh_stats
      delete :remove_image
    end
  end

  # Telegram Sessions (авторизация через Pyrogram)
  resources :telegram_sessions, only: [ :index, :new, :destroy ] do
    collection do
      post :send_code
    end
    member do
      post :verify_code
      get :twofa
      post :verify_2fa
    end
  end

  # Projects
  resources :projects do
    member do
      post :archive
      post :activate
    end

    # Style settings (анализ стиля)
    resource :style_settings, only: [ :show, :update ], controller: "projects/style_settings" do
      post :analyze
      delete :reset
    end

    # Style samples (примеры для анализа)
    resources :style_samples, only: [ :index, :create, :destroy ], controller: "projects/style_samples" do
      collection do
        post :import_from_telegram
      end
      member do
        post :toggle
      end
    end

    # Style documents (загруженные документы)
    resources :style_documents, only: [ :index, :create, :destroy ], controller: "projects/style_documents" do
      member do
        post :toggle
      end
    end

    # Nested resources
    resources :telegram_bots do
      member do
        post :verify
        get :subscriber_analytics
      end

      resources :invite_links, only: [ :index, :new, :create, :destroy ]
    end

    # Nested posts (only new/create, other actions use top-level routes)
    resources :posts, only: [ :new, :create ]
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
      resources :posts, only: [ :index, :show, :create, :update, :destroy ]

      # Projects API
      resources :projects, only: [ :index, :show ]
    end
  end

  # Subscriptions
  resources :subscriptions, only: [ :index ] do
    collection do
      post :upgrade
      post :downgrade
      post :cancel
    end
  end

  # Webhooks
  namespace :webhooks do
    post "telegram/:bot_token", to: "telegram#receive", as: :telegram
    # Robokassa может вызывать Result URL как через GET, так и через POST
    match "robokassa/result", to: "robokassa#result", as: :robokassa_result, via: [ :get, :post ]
    get "robokassa/success", to: "robokassa#success", as: :robokassa_success
    get "robokassa/fail", to: "robokassa#fail", as: :robokassa_fail
    post "channel_sync", to: "channel_sync#receive", as: :channel_sync
    post "style_import", to: "style_import#receive", as: :style_import
  end

  # Static pages
  get "pages/home"
  get "terms", to: "pages#terms", as: :terms
  get "privacy", to: "pages#privacy", as: :privacy
  get "about", to: "pages#about", as: :about
  get "careers", to: "pages#careers", as: :careers
  get "contacts", to: "pages#contacts", as: :contacts
  post "contacts", to: "pages#submit_contact", as: :submit_contact
  get "docs", to: "pages#docs", as: :docs

  # Blog
  get "blog", to: "articles#index", as: :blog
  resources :articles, only: [ :index, :show ], param: :slug

  # Admin namespace - Simple admin without Administrate
  namespace :admin do
    root to: "dashboard#index"

    resources :users, only: [ :index, :show, :edit, :update, :destroy ]
    resources :projects, only: [ :index, :show, :destroy ]
    resources :posts, only: [ :index, :show, :destroy ]
    resources :telegram_bots, only: [ :index, :show, :destroy ]
    resources :subscriptions
    # AI Settings (singleton resource)
    resource :ai_settings, only: [ :edit, :update ]

    # Payment Settings (Robokassa)
    resource :payment_settings, only: [ :edit, :update ]

    # Site Settings (Feature flags)
    resource :site_settings, only: [ :edit, :update ]

    # Page SEO (SEO настройки публичных страниц)
    resources :page_seos, only: [ :index, :edit, :update ]

    # Sponsor Banners (Рекламные баннеры)
    resources :sponsor_banners

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
    resources :invite_links, only: [ :index, :show, :destroy ]

    # Логи AI
    resources :ai_usage_logs, only: [ :index ]

    # Уведомления
    resources :notifications, only: [ :index, :show ]

    # Платежи с возвратом
    resources :payments, only: [ :index, :show ] do
      member do
        post :refund
        post :confirm
        post :cancel
      end
    end

    # ROI дашборд
    get "roi", to: "roi#index"

    # Audience analytics дашборд
    get "audience", to: "audience#index"

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
  get "up" => "rails/health#show", as: :rails_health_check
end
