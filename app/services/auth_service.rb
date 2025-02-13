# frozen_string_literal: true

class AuthService < AppService
  def initialize(user = nil)
    super(user, User)
  end

  def signup(**params)
    user = User.find_by(email: params[:email])
    assert! user.blank?, on_error: t("auth.already_registered")

    user = create(params)
    { user: user, authorization: authorization_token(user) }
  end

  def login(**params)
    user = User.find_by(params.except(:password).to_h.symbolize_keys)
    assert! user, on_error: t("auth.not_registered")

    valid_password = user.authenticate(params[:password])
    assert! valid_password, on_error: t("auth.invalid_password")

    { user: user, authorization: authorization_token(user) }
  end

  private

  def authorization_token(user)
    ::Knock::AuthToken.new payload: { sub: user.id }
  end
end
