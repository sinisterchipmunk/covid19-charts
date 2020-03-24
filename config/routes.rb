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
      get :doubling_rate
    end

    member do
      get :cfr
      get :cumulative
      get :acceleration
      get :cumulative_per_million
      get :cases_per_day
      get :doubling_rate
    end
  end

  root to: 'countries#index'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
