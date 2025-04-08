Rails.application.routes.draw do
  if Rails.env.development?
    # mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end
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

  resources :suppliers
  resources :locations do
    get 'inventory', to: 'locations#inventory_data'
  end

  resources :batches
  resources :products do
    resources :batches, only: [:create, :update]
    member do
      delete :remove_category
      delete :delete_category
    end
  end

  resources :notifications, only: [:index] do
    member do
      patch :mark_as_read
    end
  end

  resources :subscriptions, only: [:new, :create]
  resources :invitations, only: [:create, :destroy]
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  get '/dashboard' => 'dashboard#index'

  get 'signup', to: 'users#new'
  get 'signout', to: 'sessions#destroy'
  get 'signin', to: 'sessions#new'
  post 'signup', to: 'users#create'

  get 'inventory', to: 'locations#inventory'
  post 'update_inventory', to: 'locations#update_inventory'

  # Add the token parameter to the route
  get '/accept_invitation/:token', to: 'invitations#accept', as: :accept_invitation

  get 'subscriptions/success', to: 'subscriptions#success'
  get 'subscriptions/cancel', to: 'subscriptions#cancel'

  # config/routes.rb
  post "billing/checkout", to: "billing#create_checkout_session", as: :create_checkout
  get "billing/portal", to: "billing#billing_portal", as: :billing_portal

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "dashboard#index"

end
