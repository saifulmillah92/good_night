# frozen_string_literal: true

module Outputs
  class Error
    attr_reader :options

    def initialize(object, options = {})
      @object = object
      @options = options
      @options[:status] ||= 422
    end

    def as_json(*_)
      { error: { code: status, message: error_message, **details } }
    end

    def root_json
      as_json
    end

    def error?
      true
    end

    def error_message
      if @object.respond_to?(:errors)
        first_error(@object)
      elsif @object.is_a?(String) || @object.is_a?(Hash) || @object.is_a?(Array)
        @object
      else
        raise TypeError, "unrecognized object for #{self.class}"
      end
    end

    def first_error(object)
      message = object.errors.to_a.first
      return message unless message.to_s.end_with?("is invalid")

      key = object.errors.attribute_names.first
      return message if key == :base
      return message unless object.respond_to?(key)

      nested_object = object.send(key)
      return message unless nested_object.respond_to?(:errors)
      return message unless nested_object.errors.size == 1

      attr_name = key.to_s.tr(".", "_").humanize

      if object.class.respond_to?(:human_attribute_name)
        attr_name = object.class.human_attribute_name(key, default: attr_name)
      end

      message = first_error(nested_object)
      attr_name << " " << message[0].downcase << message[1..]
    end

    def status
      Rack::Utils.status_code(@options[:status])
    end

    def details
      { details: error_details }.compact
    end

    def error_details
      @options[:details]
    end
  end
end
