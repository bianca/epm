Epm::Application.routes.draw do

  devise_for :users

  root 'events#index'

  resources :events do
    member do
      patch 'attend'
      patch 'unattend'
    end
  end

end
