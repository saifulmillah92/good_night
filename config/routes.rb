require_relative 'routes_helpers'

Rails.application.routes.draw do
  extend RoutesHelpers
  default_url_options host: ENV.fetch("API_HOST", nil)

  # root not found
  get      '/' => "errors#route_not_found"

  # AUTHENTICATION
  get      'auth'         => 'auth#index'
  # LOGIN #
  post     'auth/sign-in' => 'auth#login'

  # SIGN-UP #
  post     'auth/sign-up' => 'auth#signup'

  # HANDLE ROOT NOT FOUND #
  match '*path' => 'errors#route_not_found', via: :all, constraints: lambda { |req|
    req.path.exclude? 'rails/active_storage'
  }
end
