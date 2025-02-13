# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Auth" do
  before do
    @nick = User.create(email: "nick@gmail.com", password: "password")
  end

  describe "Auth" do
    it "returns ok" do
      get_json "/auth", {}, as_user(@nick)
      expect_response(:ok, data: { id: Integer, email: @nick.email })
    end

    it "returns unauthenticated when token is expired" do
      token = create_access_token(@nick).token
      Timecop.freeze(2.days.from_now.to_date) do
        get_json "/auth", {}, { Authorization: "Bearer #{token}" }
        expect_error_response(401, "Unauthorized")
      end
    end

    it "returns unauthenticated when token is not provided" do
      get_json "/auth", {}
      expect_error_response(401, "Unauthorized")
    end
  end

  describe "Login" do
    let(:params) { { email: @nick.email, password: "password" } }

    it "returns ok" do
      post_json "/auth/sign-in", params
      expect_response(
        201,
        {
          message: "OK",
          data: { id: Integer, token: String },
        },
      )
    end

    it "returns error when email is not exist" do
      params[:email] = "a@.co"
      post_json "/auth/sign-in", params
      expect_error_response(422, "Email or Password is invalid")
    end

    it "returns error when password is invalid" do
      params[:password] = "11111"
      post_json "/auth/sign-in", params
      expect_error_response(422, "Email or Password is invalid")
    end
  end

  describe "Signup" do
    let(:params) { { email: "user@gmail.com", password: "password" } }

    it "returns ok" do
      post_json "/auth/sign-up", params
      expect_response(
        201,
        {
          message: "OK",
          data: { id: Integer, token: String },
        },
      )
    end

    it "returns error when email is not empty" do
      params[:email] = nil
      post_json "/auth/sign-up", params
      expect_error_response(422, "Email can't be blank")
    end

    it "returns error when password is invalid" do
      params[:password] = nil
      post_json "/auth/sign-up", params
      expect_error_response(422, "Password can't be blank")
    end
  end
end
