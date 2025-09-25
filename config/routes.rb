Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'

  namespace :api do
    namespace :v1 do
      # 크롤링 엔드포인트
      namespace :crawling do
        post :seoul              # 서울 전체 geohash 매물 수집
        post :gyeonggi           # 경기도 전체 geohash 매물 수집
        post :all                # 서울+경기도 전체 geohash 수집
      end

      # 매물 조회 API
      resources :properties, only: [] do
        collection do
          get :map                 # 지도 기반 매물 조회
          get :room_types          # room_type 옵션 조회
        end
      end
    end
  end

  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  root to: proc { [200, {}, ['Hommuting Crawling Server']] }
end
