# frozen_string_literal: true

module V1
  class UsersController < V1::ResourceController
    private

    def service
      UserService.new(current_user)
    end
  end
end
