# frozen_string_literal: true

module Outputs
  class Empty < Outputs::Api
    def format
      {}
    end
  end
end
