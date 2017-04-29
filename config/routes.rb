Epm::Application.routes.draw do

  resources :agencies do
    get 'order', on: :collection
  end

  resources :equipment_sets do
    get 'order', on: :collection
    get 'resolve_issue', on: :member
  end

  root 'events#dashboard'

  devise_for :users, controllers: { registrations: 'registrations' }
  resources :users, only: [:index, :show, :edit, :update, :destroy] do
    resources :roles, only: [:create, :destroy], shallow: true
    get 'map', on: :collection
    get 'properties', on: :collection
    patch 'deactivate', on: :member
    get 'invite'
  end
  get 'me', to: 'users#me'
  get 'my_wards', to: 'users#my_wards'

  resources :events do
    collection do 
      get 'calendar'
      get 'dashboard'
      get 'stats'
      get 'schedule'
    end
    member do
      get 'who'
      get 'cancel', to: 'events#ask_to_cancel'
      patch 'cancel'
      patch 'approve'
      patch 'claim'
      patch 'unclaim'
      patch 'attend'
      patch 'unattend'
      patch 'invite'
      patch 'take_attendance'
    end
  end

  # for configurable_engine gem; it generates its own routes as well which are unused
  put 'settings', to: 'settings#update', as: 'settings'
  get 'settings', to: 'settings#show'

  resources :trees do
    get 'copy', on: :member
    get 'copy_location', on: :member
    get 'inviteowner', on: :member
    get 'mine', on: :collection
    get 'dashboard', on: :collection
    get 'closest', on: :collection
  end   

  get 'geocode', to: 'geocode#index'

end