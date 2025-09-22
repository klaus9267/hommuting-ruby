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
        post :seoul     # 서울 전체 매물 수집
        post :gyeonggi  # 경기도 전체 매물 수집
        post :all       # 서울+경기도 전체 수집
        get :status     # 수집 상태 확인
      end
    end
  end
  
  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check
  
  # API-only app, no root route needed
  root to: proc { [200, {}, ['API Server Running']] }
end
