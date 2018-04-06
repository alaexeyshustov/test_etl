require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'

  root 'events#index'

  get  '/events', to: 'events#index' , as: 'events'
  post '/events', to: 'events#create', as: 'create_event'
end
