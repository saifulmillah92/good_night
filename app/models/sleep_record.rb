# frozen_string_literal: true

class SleepRecord < ApplicationRecord
  belongs_to :user

  scope :previous_week,
        lambda {
          where(
            "sleep_records.created_at >= ? AND sleep_records.created_at < ?",
            1.week.ago.beginning_of_week,
            1.week.ago.end_of_week,
          )
        }
end
