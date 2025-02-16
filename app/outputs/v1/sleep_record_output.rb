# frozen_string_literal: true

module V1
  class SleepRecordOutput < Outputs::Api
    def format
      {
        id: @object.id,
        user_id: @object.user.id,
        user: UserOutput.new(user, use: :format),
        clock_in: @object.clock_in,
        clock_out: @object.clock_out,
        duration: @object.duration,
        **info,
      }
    end

    private

    def info
      return {} unless @object.duration

      info = "Record #{@object.id} from user #{user.email} has " \
               "#{humanize_seconds(@object.duration)} of sleep length"

      { info: info }
    end

    def user
      @user ||= @object.user
    end

    def humanize_seconds(seconds)
      return unless seconds
      return @humanize_seconds if defined? @humanize_seconds

      hours = seconds / 3600
      minutes = (seconds % 3600) / 60
      remaining_seconds = seconds % 60

      parts = []
      parts << "#{hours} hours" if hours.positive?
      parts << "#{minutes} minutes" if minutes.positive?
      parts << "#{remaining_seconds} seconds" if remaining_seconds.positive?

      @humanize_seconds = parts.join(", ")
    end
  end
end
