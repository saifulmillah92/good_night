# frozen_string_literal: true

module Outputs
  class Api
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::NumberHelper
    attr_reader :options

    def self.root_key
      :data
    end

    def self.array(models, **options)
      Outputs::Array.new(models, **options, item_output: self)
    end

    def initialize(object, options = {})
      @object = object
      @options = options
      @options[:status] ||= 200
      @options[:status] = Rack::Utils.status_code(@options[:status])
      @options[:message] ||= I18n.t("ok")
    end

    def root_json
      if error?
        error_format
      elsif self.class.root_key
        as_root_json
      else
        as_json
      end
    end

    def as_root_json
      {
        code: @options[:status],
        message: @options[:message],
        self.class.root_key.to_s => as_json,
      }
    end

    def as_json(*_)
      format_method = @options[:use] || :format
      format_method = :error_format if error?
      send(format_method).as_json
    end

    def status
      Rack::Utils.status_code(error? ? error_status : @options[:status])
    end

    ################################
    # Overridable parts start here #
    ################################

    def format
      @object.as_json
    end

    def full_format
      format
    end

    def error?
      @object.respond_to?(:errors) && @object.errors.any?
    end

    def error_format
      Outputs::Error.new(@object, status: error_status, details: error_details)
    end

    def error_status
      Outputs::Error.new(@object).status
    end

    def error_details
      nil
    end

    def maybe(key_name, &block)
      block ||= key_name.to_sym.to_proc
      is_displayable = send(:"show_#{key_name}?")
      is_displayable ? { key_name => block.call(self) } : {}
    end
  end
end
