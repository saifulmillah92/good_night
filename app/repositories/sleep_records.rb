# frozen_string_literal: true

# SleepRecords
class SleepRecords < ApplicationRepository
  private

  def default_scope
    SleepRecord.previous_week.includes(:user)
  end

  def filter_by_following(value)
    return @scope unless value.in?([1, "true", true])

    @scope.where(
      follows_table
        .project(Arel.sql("1"))
        .where(
          follows_table[:follower_id].eq(current_user.id)
          .and(follows_table[:followed_id].eq(table[:user_id])),
        )
        .exists,
    )
  end

  def current_user
    @current_user ||= @options[:current_user]
  end

  def follows_table
    Follow.arel_table
  end
end
