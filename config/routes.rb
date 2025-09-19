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

      # 크롤링 엔드포인트
      namespace :crawling do
        post :seoul
        post :gyeonggi
        post :all
        get :status
      end
    end
  end
  
  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check
  
  # API-only app, no root route needed
  root to: proc { [200, {}, ['API Server Running']] }
end
