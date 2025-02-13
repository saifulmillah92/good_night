# frozen_string_literal: true

# ErrorController
class ErrorsController < ApplicationController
  skip_before_action :authenticate_user

  def route_not_found
    render_route_not_found
  end
end
