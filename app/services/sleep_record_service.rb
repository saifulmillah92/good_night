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
    create(user: @user, clock_in: Current.time)
  rescue ActiveRecord::RecordNotUnique
    raise UniqueViolation, t("sleep_records.already_active")
  end

  def clock_out!
    transaction do
      sleep_record = @user.sleep_records.where(clock_out: nil).lock.first
      assert! sleep_record.present?,
              on_error: t("sleep_records.not_clocked_in")

      sleep_record.clock_out = Current.time
      sleep_record.duration = (sleep_record.clock_out - sleep_record.clock_in).to_i
      sleep_record.save!
      sleep_record
    end
  end
end
