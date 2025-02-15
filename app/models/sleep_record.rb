# frozen_string_literal: true

class SleepRecord < ApplicationRecord
  belongs_to :user

  scope :previous_week, -> { where(created_at: 1.week.ago.all_week) }
end
