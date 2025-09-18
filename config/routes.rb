Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  namespace :api do
    namespace :v1 do
      resources :properties, only: [:index, :show] do
        collection do
          get :search
          get :stats
          get :by_area
        end
      end
    end
  end
  
  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check
  
  # API-only app, no root route needed
  root to: proc { [200, {}, ['API Server Running']] }
end
