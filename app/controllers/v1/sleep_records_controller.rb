# frozen_string_literal: true

module V1
  class SleepRecordsController < V1::ResourceController
    def clock_in
      service.clock_in!
      render_ok
    end

    def clock_out
      service.clock_out!
      render_ok
    end

    private

    def service
      SleepRecordService.new(current_user)
    end
  end
end
