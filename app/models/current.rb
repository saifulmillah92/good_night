# frozen_string_literal: true

module Current
  module Ext
    def class_accessor(name)
      Ext.module_eval do
        define_method(:"#{name}=") { |value| RequestStore.store[name] = value }

        define_method(name) do |&block|
          error_message = "please set Current.#{name}, e.g. Current.#{name} = obj"
          block ||= proc { raise StandardError, error_message }
          RequestStore.store.fetch(name, &block)
        end
      end
    end
  end

  extend Ext

  class_accessor :limit
  class_accessor :offset
  class_accessor :page
  class_accessor :user

  class << self
    def time_zone
      Time.find_zone(ENV.fetch("TIME_ZONE", "Jakarta"))
    end

    def time(*args)
      args.any? ? time_zone.local(*args) : time_zone.now
    end

    def use_zone(&block)
      Time.use_zone(time_zone, &block)
    end
  end
end
