# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Auth" do
  before do
    @nick = User.create(email: "nick@gmail.com", password: "password")
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
  end
end
