Rails.application.routes.draw do
  resources :reports
  resources :countries do
    collection do
      get :heatmap
      get :cumulative
      get :cfr
      get :acceleration
      get :cumulative_per_million
      get :cases_per_day
    end

    member do
      get :cfr
      get :totals
      get :acceleration
      get :cumulative_per_million
      get :cases_per_day
    end
  end

  root to: 'countries#index'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
