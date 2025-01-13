Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "monitors/lb" => "monitors#lb"

  namespace :api do
    namespace :v1 do
      resources :gift_cards, only: [ :show, :update ]
    end
  end

  # okta login related routes
  devise_for :users, class_name: "User", controllers: { omniauth_callbacks: "sessions" }
  ActiveAdmin.routes(self)
  devise_scope :user do
    get "users/sign_out", to: "devise/sessions#destroy", as: :destroy_user_session
  end
  get "/login/new", to: "login#new"

  # Defines the root path route ("/")
  get "/", to: redirect("/admin"), as: :root
end
