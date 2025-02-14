# frozen_string_literal: true

# SleepRecord
class SleepRecordService < AppService
  def initialize(user)
    super(user, SleepRecord, SleepRecords.new)
  end

  def clock_in(params)
    # TODO
  end

  def clock_out(followed_id)
    # TODO
  end
end
