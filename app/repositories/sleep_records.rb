# frozen_string_literal: true

# SleepRecords
class SleepRecords < ApplicationRepository
  private

  def default_scope
    SleepRecord.last_week.includes(:user)
  end

  def filter_by_following(value)
    return @scope unless value.in?([1, "true", true])

    @scope.where(user_id: current_user.followeds.select(:id))
  end

  def current_user
    @current_user ||= @options[:current_user] || @options["current_user"]
  end
end
