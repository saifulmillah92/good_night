# frozen_string_literal: true

class AuthController < ApplicationController
  before_action :authenticate_user, only: :index

  def index
    render_json current_user,
                V1::UserOutput,
                excluded_is_followed: true,
                authorization: token,
                use: :auth_format
  end

  def signup
    result = service.signup(**auth_params)
    render_json result[:user],
                V1::UserOutput,
                authorization: result[:authorization],
                status: :created,
                message: t("ok"),
                use: :signup_format
  end

  def login
    result = service.login(**auth_params)
    render_json result[:user],
                V1::UserOutput,
                authorization: result[:authorization],
                status: :created,
                message: t("ok"),
                use: :login_format
  end

  private

  def service
    AuthService.new
  end

  def auth_params
    params.slice :email, :password
  end
end
