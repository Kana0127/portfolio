Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#top"

  get "mypage", to: "mypages#show", as: :mypage

  resources :users, only: %i[new create]

  # ロードマップ目標（中期目標）。編集・削除は次以降のIssueで実装予定
  resources :roadmap_goals, only: %i[index new create show]

  resources :monthly_goals, only: %i[index new create edit update destroy] do
    resources :weekly_goals, only: %i[new create edit update destroy]
    # 月目標1つにつき月次振り返り1件のみ → 単数 resource
    resource :monthly_review, only: %i[new create show]
  end

  # daily_records / weekly_review は週目標配下にネスト
  # URL: /weekly_goals/:weekly_goal_id/daily_records/new
  # URL: /weekly_goals/:weekly_goal_id/weekly_review/new (singular: 1 weekly_goal に 1 review)
  resources :weekly_goals, only: [] do
    resources :daily_records, only: %i[new create]
    resource :weekly_review, only: %i[new create show]
  end

  get "reviews",         to: "reviews#index",          as: :reviews
  get "reviews/archive", to: "reviews_archive#index",  as: :reviews_archive

  get    "login",  to: "sessions#new"
  post   "login",  to: "sessions#create"
  delete "logout", to: "sessions#destroy"
end
