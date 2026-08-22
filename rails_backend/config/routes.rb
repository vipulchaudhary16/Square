Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  mount Dashboard::Engine, at: "/api/dashboard"

  scope module: "api/v1", path: "/api", defaults: { format: :json } do
    # Auth
    post   "auth/signup",          to: "auth#signup"
    post   "auth/login",           to: "auth#login"
    post   "auth/refresh",         to: "auth#refresh"
    post   "auth/logout",          to: "auth#logout"
    post   "auth/logout-all",      to: "auth#logout_all"
    post   "auth/forgot-password", to: "auth#forgot_password"
    post   "auth/reset-password",  to: "auth#reset_password"
    get    "auth/me",              to: "auth#me"

    # Expenses
    resources :expenses, only: [:create, :index, :show, :update, :destroy] do
      member { post :comments }
    end

    # Analysis (period-scoped spending/income summary + category breakdown)
    get "analysis", to: "analysis#show"

    # Groups
    resources :groups, only: [:create, :index, :show] do
      member do
        post :invite
        post :members
        get  :expenses, action: :group_expenses
        post :settle
      end
      collection { post :join }
    end

    # Users
    scope :users do
      get   "search",    to: "users#search"
      get   "me/flags",  to: "users#flags"
      patch "me/flags",  to: "users#update_flags"
    end

    # Finance resources
    resources :incomes,     only: [:create, :index, :show, :update, :destroy] do
      member { post :comments }
    end
    resources :investments, only: [:create, :index, :show, :update, :destroy] do
      member { post :comments }
    end
    resources :contacts, only: [:index, :create, :update] do
      collection { get :search }
      member      { get :loans }
    end
    resources :loans, only: [:create, :index, :show, :update, :destroy] do
      member do
        post  :comments
        patch :confirmation
        get   'payments',  to: 'loan_payments#index'
        post  'payments',  to: 'loan_payments#create'
        post  'reminders', to: 'loan_reminders#create'
      end
    end

    # Budgets
    resources :budgets, only: [:create, :index, :update, :destroy]

    # Categories
    resources :categories, only: [:index, :create, :update, :destroy]
  end
end
