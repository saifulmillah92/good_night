# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :validatable

  alias authenticate valid_password?

  has_many :follower_relationships,
           foreign_key: :followed_id,
           class_name: "Follow",
           dependent: :destroy,
           inverse_of: :followed

  has_many :followers, through: :follower_relationships, source: :follower

  has_many :followed_relationships,
           foreign_key: :follower_id,
           class_name: "Follow",
           dependent: :destroy,
           inverse_of: :follower

  has_many :followeds, through: :followed_relationships, source: :followed
end
