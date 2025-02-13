# frozen_string_literal: true

module Factories
  def access_token(user, **params)
    @_tokens ||= {}
    @_tokens[[user, params]] ||= create_access_token(user, **params).token
  end

  def create_access_token(user, **params)
    ::Knock::AuthToken.new payload: { sub: user.id, **params }
  end
end
