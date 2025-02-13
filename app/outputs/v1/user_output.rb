# frozen_string_literal: true

module V1
  class UserOutput < Outputs::Api
    def format
      {
        id: @object.id,
        email: @object.email,
      }
    end

    def login_format
      format.merge(token: authorization.token)
    end

    def signup_format
      format.merge(token: authorization.token)
    end

    def auth_format
      format
    end

    private

    def authorization
      @options[:authorization]
    end
  end
end
