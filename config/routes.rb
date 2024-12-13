Rails.application.routes.draw do
  ActiveAdmin.routes(self)
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "monitors/lb" => "monitors#lb"

  namespace :api do
    namespace :v1 do
      resources :gift_cards, only: [:show, :update]
    end
  end

  # Defines the root path route ("/")
  get "/", to: redirect("/admin")
end
