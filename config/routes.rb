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
      resources :people, only: %i[show update]
    end
  end

  resources :people, except: %i[edit update new create destroy] do
    member do
     # match 'versions/:version', :action => :versions_show, :as => 'version_of', :version => /\d+/
      get :versions
      # match 'versions/compare/:from/:to',
      #   :action => :versions_compare,
      #   :constraints => { :from => /\d+/, :to => /\d+/ }
    end
    collection do
      get  :list
      get  :family_chart
      post :update_tree
    end
    resources :children, only: %i[create destroy]
    resources :notes
  end

  root to: 'people#index'
end
