# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Auth" do
  before do
    @nick = User.create(email: "nick@gmail.com", password: "password")
    @capt = User.create(email: "capt@gmail.com", password: "password")
    @hulk = User.create(email: "hulk@gmail.com", password: "password")
    100.times { |i| User.create(email: "user#{i}@gmail.co", password: "password") }
  end

  describe "List of users" do
    it "returns ok" do
      get_json "/v1/users", {}, as_user(@nick)
      expect_response(
        :ok,
        data: [
          { id: Integer, email: String },
          { id: Integer, email: String },
          { id: Integer, email: String },
          { id: Integer, email: String },
          { id: Integer, email: String },
        ],
      )
    end

    it "returns correct data when using limit" do
      get_json "/v1/users", { limit: 10 }, as_user(@nick)
      expect_response(:ok)
      expect(response_body[:data].size).to eq(10)

      get_json "/v1/users", { limit: 5 }, as_user(@nick)
      expect(response_body[:data].size).to eq(5)
    end

    it "returns correct data when using offset" do
      get_json "/v1/users", { offset: 0 }, as_user(@nick)
      expect_response(:ok)

      prev_ids = response_body[:data].pluck(:id)
      get_json "/v1/users", { offset: 10 }, as_user(@nick)
      expect_response(:ok)

      current_ids = response_body[:data].pluck(:id)
      expect(prev_ids).not_to eq(current_ids)
    end

    it "returns ok filtered by q" do
      get_json "/v1/users", { q: "nick" }, as_user(@nick)
      expect_response(
        :ok,
        data: [{ id: Integer, email: "nick@gmail.com" }],
      )

      expect(response_body[:data].size).to eq(1)
    end

    it "returns ok when sort direction is desc" do
      params = { sort_direction: "desc", sort_column: "id" }
      get_json "/v1/users", params, as_user(@nick)

      first_data_id = response_body[:data].first[:id]
      second_data_id = response_body[:data].second[:id]
      expect(first_data_id).to be > second_data_id
    end

    it "doesn't do n+1 query" do
      expect do
        get_json "/v1/users", {}, as_user(@nick)
      end.not_to exceed_query_limit(3)
    end
  end

  describe "User Detail" do
    it "returns ok" do
      get_json "/v1/users/#{@nick.id}", {}, as_user(@nick)
      expect_response(
        :ok,
        data: { id: @nick.id, email: @nick.email },
      )
    end

    it "returns error when id is invalid" do
      get_json "/v1/users/-9999", {}, as_user(@nick)
      expect_error_response(:not_found)
    end

    it "includes followers and followeds count" do
      @nick.followers << @capt
      @nick.followers << @hulk
      @nick.followeds << @capt

      get_json "/v1/users/#{@nick.id}", {}, as_user(@nick)
      expect_response(
        :ok,
        data: {
          id: @nick.id,
          email: @nick.email,
          followers_count: 2,
          followeds_count: 1,
        },
      )
    end
  end

  describe "Follows" do
    it "returns ok when target is valid" do
      expect(@nick.followeds_count).to eq(0)

      post_json "/v1/users/#{@capt.id}/follows", {}, as_user(@nick)
      expect_response(:ok)

      expect(@nick.reload.followeds_count).to eq(1)
    end

    it "returns error when you already followed" do
      post_json "/v1/users/#{@capt.id}/follows", {}, as_user(@nick)
      expect_response(:ok)

      post_json "/v1/users/#{@capt.id}/follows", {}, as_user(@nick)
      expect_error_response(422, "You are already following this user")
    end

    it "returns error when target is a current user" do
      post_json "/v1/users/#{@nick.id}/follows", {}, as_user(@nick)
      expect_error_response(422, "You are not able to follow yourself")
    end

    it "returns error when target is not exist" do
      post_json "/v1/users/-9999/follows", {}, as_user(@nick)
      expect_error_response(:not_found)
    end
  end

  describe "Unfollows" do
    before { @nick.followeds << @capt }

    it "returns ok" do
      expect(@nick.followeds_count).to eq(1)

      delete_json "/v1/users/#{@capt.id}/unfollows", {}, as_user(@nick)
      expect_response(:ok, message: "Unfollowed successfully")

      expect(@nick.reload.followeds_count).to eq(0)
    end

    it "returns error when target is not exist" do
      delete_json "/v1/users/-9999/follows", {}, as_user(@nick)
      expect_error_response(:not_found)
    end
  end
end
