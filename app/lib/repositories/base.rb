# frozen_string_literal: true

module Repositories
  class Base < Repositories::Basic
    def hashes
      Repositories::Hashes.new(@scope, @options)
    end
  end
end
