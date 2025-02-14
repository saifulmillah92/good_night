require_relative "routes_helpers"

Rails.application.routes.draw do
  extend RoutesHelpers
  default_url_options host: ENV.fetch("API_HOST", nil)

  # ROUTE NOT FOUND
  get      "/" => "errors#route_not_found"

  # AUTHENTICATION
  get      "auth"         => "auth#index"
  # LOGIN #
  post     "auth/sign-in" => "auth#login"
  # SIGN-UP #
  post     "auth/sign-up" => "auth#signup"

  api(:v1, module: "v1") do
    # USERS
    get    "users"                     => "users#index"
    get     "users/:id"                => "users#show"
    post    "users/:user_id/follows"   => "users#follows"
    delete  "users/:user_id/unfollows" => "users#unfollows"

    # SLEEP RECORDS
    get   "sleeps"           => "sleeps#index", query_override(sort_column: "duration", sort_direction: )
    post  "sleeps/clock-in"  => "sleeps#follows"
    post  "sleeps/clock-out" => "sleeps#unfollows"
  end

  # HANDLE ROUTE NOT FOUND #
  match "*path" => "errors#route_not_found", via: :all, constraints: lambda { |req|
    req.path.exclude? "rails/active_storage"
  }
end
