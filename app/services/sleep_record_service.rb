# frozen_string_literal: true

# SleepRecord
class SleepRecordService < AppService
  def initialize(user)
    super(user, SleepRecord, SleepRecords.new)
  end

  def all(query = {})
    query[:following] ||= true
    query[:current_user] = @user

    @repository.filter(query).limited.to_a
  end

  def clock_in!
    assert! @user.latest_sleep_record.blank?,
            on_error: t("sleep_records.there_is_active_sleep_records")

    create(user: @user, clock_in: Current.time)
  end

  def clock_out!
    sleep_record = @user.latest_sleep_record
    assert! sleep_record.present?,
            on_error: t("sleep_records.no_active_sleep_records")

    sleep_record.clock_out = Current.time
    sleep_record.duration = (sleep_record.clock_out - sleep_record.clock_in).to_i
    sleep_record.save!
  end
end
