# frozen_string_literal: true

module V1
  class SleepRecordsController < V1::ResourceController
    def clock_in
      # TODO
    end

    def clock_out
      # TODO
    end

    private

    def service
      SleepRecordService.new(current_user)
    end
  end
end
