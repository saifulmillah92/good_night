# frozen_string_literal: true

class User < ApplicationRecord
  extend HasCount

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

  has_count :followers_count,
            association: :follower_relationships,
            foreign_key: :followed_id,
            class_name: "Follow"

  has_count :followeds_count,
            association: :followed_relationships,
            foreign_key: :follower_id,
            class_name: "Follow"

  has_many :sleep_records,
           class_name: "SleepRecord",
           dependent: :destroy

  def latest_sleep_record
    sleep_records.where(clock_out: nil)
                 .order(created_at: :desc)
                 .first
  end
end
