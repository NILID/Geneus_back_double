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
        post   'auth/register', to: 'auth/registrations#create'
        post   'auth/password',       to: 'auth/passwords#create'
        patch  'auth/password',       to: 'auth/passwords#update'
      end
      get 'auth/me', to: 'users#show'
      resources :people, only: %i[show update] do
        collection do
          get :map_locations
          get :recent
        end
        resources :facts, only: %i[index create], module: :people
      end
      resources :gallery_photos, only: %i[index create update destroy] do
        resources :comments, only: %i[index create], module: :gallery_photos
      end
      resources :ideas, only: %i[index create] do
        resources :comments, only: %i[index create], module: :ideas
      end
    end
  end

  resources :people, only: [] do
    collection do
      get  :list
      get  :family_chart
      post :update_tree
    end
  end

  root to: 'people#index'
end
