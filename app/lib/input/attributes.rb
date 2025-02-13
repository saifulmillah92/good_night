# frozen_string_literal: true

module Input
  module Attributes
    def self.new(value)
      if value.is_a?(Hash)
        value.symbolize_keys
      elsif value.nil?
        Null.instance
      else
        Invalid.new(value)
      end
    end

    class Nested
      def initialize
        @list = {}
      end

      def clear_all
        @list = {}
      end

      def clear(name)
        @list.delete(name.to_sym)
      end

      def get(name)
        @list.fetch(name.to_sym) { @list[name.to_sym] = yield }
      end
    end

    class Invalid
      def initialize(value)
        @value = value
      end

      def [](_)
        nil
      end

      def []=(_, _)
        nil
      end

      def each
        self
      end

      def key?(_)
        false
      end

      def reject
        self
      end

      def transform_keys
        self
      end

      def dup
        self
      end

      def to_h
        self
      end

      def select
        self
      end
    end

    class Null
      include Singleton

      def [](_)
        nil
      end

      def []=(_, _)
        nil
      end

      def each
        self
      end

      def key?(_)
        false
      end

      def reject
        self
      end

      def transform_keys
        self
      end

      def dup
        self
      end

      def to_h
        nil
      end

      def select
        self
      end
    end
  end
end
