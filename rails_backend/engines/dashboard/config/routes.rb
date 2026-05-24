Dashboard::Engine.routes.draw do
  root to: "dashboard#show", via: [:get]
end
