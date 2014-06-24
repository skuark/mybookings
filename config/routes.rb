Rails.application.routes.draw do

  devise_for :users, controllers: { omniauth_callbacks: 'omniauth_callbacks' }

  root 'application#index'

  resources :bookings do
    get :edit_feedback
    put :set_feedback
  end

  namespace :admin do
    resources :resources do
      put :switch_availability
    end

    resources :resource_types
    resources :users
  end

end
