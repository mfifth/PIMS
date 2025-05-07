Rails.application.routes.draw do
  if Rails.env.development?
    # mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end

  mount StripeEvent::Engine, at: '/stripe/webhooks'
  mount GoodJob::Engine => 'good_job'

  post "/graphql", to: "graphql#execute"
  get "users/new"
  get "users/create"

  resource :session
  resources :passwords, param: :token

  resources :users do
    member do
      get :settings
      put :update_settings
      post :send_test_email
      post :send_test_text
    end
  end

  resources :recipe_items, only: [] do
    collection do
      get :unit_options
    end
  end

  resources :suppliers
  resources :locations do
    get 'inventory_data', to: 'locations#inventory_data'
    member do
      get 'categories'
      post :import_products
      get :sample_csv
    end
  end

  resources :batches
  resources :products do
    resources :batches, only: [:create, :update]
    member do
      delete :remove_category
      delete :delete_category
    end
  end

  resources :recipes do
    resources :recipe_items, only: [:create, :update, :destroy]
    collection do
      get :product_search
    end
  end  

  resources :notifications, only: [:index] do
    member do
      patch :mark_as_read
    end
    collection do
      patch :mark_all_as_read
    end
  end

  resources :subscriptions, only: [:new, :create]
  resources :invitations, only: [:create, :destroy]
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  get '/dashboard' => 'dashboard#index'
  delete "/delete_account" => 'accounts#destroy'

  get 'signup', to: 'users#new'
  get 'signout', to: 'sessions#destroy'
  get 'signin', to: 'sessions#new'
  post 'signup', to: 'users#create'

  get 'inventory', to: 'locations#inventory'
  post 'update_inventory', to: 'locations#update_inventory'

  get 'inventory_items/lookup', to: 'inventory_items#lookup'

  get 'subscriptions/success', to: 'subscriptions#success'
  get 'subscriptions/cancel', to: 'subscriptions#cancel'

  get '/confirm_email/:token', to: 'confirmations#show', as: 'confirm_email'
  get '/invitations/:token/confirm', to: 'invitations#confirm', as: 'confirm_invitation'
  post '/invitations/:token/confirm', to: 'invitations#confirm'
  get '/invitations/:token/accept', to: 'invitations#accept', as: 'accept_invitation'

  get "billing/portal", to: "billing#billing_portal", as: :billing_portal

  get  "/square/oauth/start",    to: "square#start"
  get  "/square/oauth/callback", to: "square#callback"

  post "/square/sync_data", to: "square#sync_data", as: :square_sync_data
  post '/square/webhook', to: 'square#webhook'

  get  '/clover/oauth/start',    to: 'clover#start'
  get  '/clover/oauth/callback', to: 'clover#callback'

  post "/clover/webhook", to: "clover#webhook"
  post "/clover/sync_data", to: "clover#sync_data", as: :clover_sync_data

  get '/contact_us', to: 'pages#contact_us', as: :contact
  post '/contact_us_create', to: 'pages#contact_us_create'

  get '/privacy_policy', to: 'pages#privacy_policy'
  get '/eula', to: 'pages#eula'

  root to: 'pages#home'
end
