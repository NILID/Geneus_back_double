Rails.application.routes.draw do
  devise_for :users, skip: :all

  if Rails.env.development?
    get '/.well-known/appspecific/com.chrome.devtools.json', to: proc { [200, {}, ['']] }
  end

  namespace :api do
    namespace :v1 do
      devise_scope :user do
        post   'auth/login',    to: 'auth/sessions#create'
        delete 'auth/logout',   to: 'auth/sessions#destroy'
        post   'auth/password',       to: 'auth/passwords#create'
        patch  'auth/password',       to: 'auth/passwords#update'
        post   'auth/invitations/link', to: 'auth/invitations#create_link'
        post   'auth/invitations',    to: 'auth/invitations#create'
        patch  'auth/invitations',    to: 'auth/invitations#update'
      end
      get   'auth/me', to: 'users#show'
      patch 'auth/me', to: 'users#update'
      get 'home/stats', to: 'home#stats'
      namespace :admin do
        resources :users, only: %i[index update]
      end
      get 'audits/filter_options', to: 'audits#filter_options'
      resources :audits, only: [:index]
      resources :people, only: %i[show update] do
        collection do
          get :map_locations
          get :recent
          get :upcoming_birthdays
          get :list
          get :family_chart
          post :update_tree
        end
        resources :facts, only: %i[index create], module: :people
      end
      resources :gallery_photos, only: %i[index create update destroy] do
        resources :comments, only: %i[index create], module: :gallery_photos
      end
      resources :ideas, only: %i[index create destroy] do
        resources :comments, only: %i[index create], module: :ideas
      end
    end
  end
end
