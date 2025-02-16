# frozen_string_literal: true

module V1
  class UserOutput < Outputs::Api
    def format
      {
        id: @object.id,
        email: @object.email,
        **followed?,
      }
    end

    def full_format
      format.merge(
        followers_count: @object.followers_count,
        followeds_count: @object.followeds_count,
      )
    end

    def login_format
      {
        id: @object.id,
        email: @object.email,
        token: authorization.token,
      }
    end

    def signup_format
      login_format
    end

    def auth_format
      full_format.merge(token: authorization)
    end

    private

    def followed?
      return {} if excluded_is_followed
      return {} if current_user.blank?
      return {} if @object.id == current_user.id

      is_followed = followeds[@object.id].present?
      is_followed ||= current_user.followeds.exists?(@object.id) if show?
      { is_followed: is_followed }
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
      @options[:excluded_is_followed] || false
    end

    def show?
      @options[:show] || false
    end
  end
end
