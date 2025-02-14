# frozen_string_literal: true

class Follow < ApplicationRecord
  belongs_to :follower, class_name: "User", inverse_of: :followed_relationships
  belongs_to :followed, class_name: "User", inverse_of: :follower_relationships
end
