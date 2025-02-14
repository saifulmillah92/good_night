# frozen_string_literal: true

class SleepRecord < ApplicationRecord
  belongs_to :user

  scope :last_week, -> { where("created_at > ?", 1.week.ago) }
end
