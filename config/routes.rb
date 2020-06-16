Rails.application.routes.draw do
  telegram_webhook TelegramWebhooksController
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :players, only: [:edit, :update, :index]
  root 'players#index'
end
