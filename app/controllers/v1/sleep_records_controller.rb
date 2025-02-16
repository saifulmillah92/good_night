# frozen_string_literal: true

module V1
  class SleepRecordsController < V1::ResourceController
    def clock_in
      result = service.clock_in!
      render_json result, status: :created
    end

    def clock_out
      result = service.clock_out!
      render_json result
    end

    private

    def service
      SleepRecordService.new(current_user)
    end
  end
end
