# frozen_string_literal: true

module V1
  class UserOutput < Outputs::Api
    def format
      {
        id: @object.id,
        email: @object.email,
      }
    end

    def full_format
      format.merge(
        followers_count: @object.followers_count,
        followeds_count: @object.followeds_count,
      )
    end

    def login_format
      format.merge(token: authorization.token)
    end

    def signup_format
      format.merge(token: authorization.token)
    end

    def auth_format
      full_format
    end

    private

    def authorization
      @options[:authorization]
    end
  end
end
