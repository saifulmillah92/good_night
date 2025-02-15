# frozen_string_literal: true

module V1
  class UserOutput < Outputs::Api
    def format
      {
        id: @object.id,
        email: @object.email,
        is_followed: followeds[@object.id].present?,
      }
    end

    def full_format
      {
        id: @object.id,
        email: @object.email,
        followers_count: @object.followers_count,
        followeds_count: @object.followeds_count,
        **followed?,
      }
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

    def followed?
      return {} if excluded_is_followed
      return {} if @object.id == current_user.id

      { is_followed: current_user.followeds.exists?(@object.id) }
    end

    def authorization
      @options[:authorization]
    end

    def current_user
      @current_user ||= @options[:current_user]
    end

    def followeds
      @options[:followeds] || []
    end

    def excluded_is_followed
      @options[:exclude_is_followed] || false
    end
  end
end
