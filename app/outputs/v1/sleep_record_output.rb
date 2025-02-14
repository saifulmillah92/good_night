# frozen_string_literal: true

module V1
  class SleepRecordOutput < Outputs::Api
    def format
      {
        id: @object.id,
        user: UserOutput.new(@object.user, use: :format),
        clock_in: @object.clock_in,
        clock_out: @object.clock_out,
        duration: humanize_seconds(@object.duration),
        detail_info: detail_info,
      }
    end

    private

    def detail_info
      "Record #{@object.id} from user #{user.email} has " \
        "#{humanize_seconds(@object.duration)} of sleep length"
    end

    def user
      @user ||= @object.user
    end

    def humanize_seconds(seconds)
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
