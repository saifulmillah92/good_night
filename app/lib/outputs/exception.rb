# frozen_string_literal: true

module Outputs
  class Exception < Outputs::Error
    def initialize(err, options = {})
      super(err, options)
      render_exception
    end

    def as_json(*_)
      super.merge(backtrace: backtrace).compact
    end

    def error_message
      @message
    end

    def namespace
      @options[:namespace]
    end

    private

    def backtrace
      @options[:debug] &&
        @object.backtrace &&
        ::Rails.backtrace_cleaner.clean(@object.backtrace)
    end

    def render_exception
      render = @object.class.name.underscore.parameterize.underscore
      render = :exception unless respond_to?(render, true)
      send(render, @object)
    end

    def active_record_record_invalid(error)
      @options[:status] = 422
      @message = error.record.errors.to_a.first
    end

    def argument_error(error)
      @options[:status] = 422
      @message = error.message
    end

    def active_model_strict_validation_failed(error)
      @options[:status] = 422
      @message = error.message
    end

    def active_model_unknown_attribute_error(error)
      @options[:status] = 422
      @message = error.message
    end

    def active_record_unknown_attribute_error(error)
      @options[:status] = 422
      @message = error.message
    end

    def active_record_statement_invalid(error)
      @options[:status] = 404
      @message = error.message
    end

    def application_record_not_found(error)
      @options[:status] = 404
      @message = error.message
    end

    def active_record_record_not_found(error)
      @options[:status] = 404
      @message = error.message
    end

    def action_controller_parameter_missing(error)
      @options[:status] = 422
      @message = error.message
    end

    def action_controller_routing_error(error)
      @options[:status] = 404
      @message = error.message
    end

    def action_controller_method_not_allowed(_err)
      @options[:status] = 403
      @message = "Request not allowed"
    end

    def action_controller_invalid_resource(error)
      @options[:status] = 422
      @message = error.message
    end

    def action_dispatch_params_parser_parse_error(error)
      @options[:status] = 400
      @message = "There was a problem in the JSON you submitted: #{error}"
    end

    def application_service_unauthenticated(error)
      @options[:status] = 401
      @message = error.message
    end

    def application_service_unauthorized(error)
      @options[:status] = 403
      @message = error.message
    end

    def app_service_unauthorized(error)
      @options[:status] = 403
      @message = error.message
    end

    def application_service_not_found(error)
      @options[:status] = 404
      @message = error.message
    end

    def application_service_invalid(error)
      @options[:status] = 422
      @message = error.message
    end

    def application_service_throttled(error)
      @options[:status] = 429
      @message = error.message
    end

    def application_service_unique_violation(error)
      @options[:status] = 422
      @message = error.message
    end

    def active_record_record_not_unique(error)
      @options[:status] = 422
      @message = error.message
    end

    def active_record_delete_restriction_error(error)
      @options[:status] = 422
      @message = error.message
    end

    def application_record_invalid(error)
      @options[:status] = 422
      @message = error.message
    end

    def application_record_not_allowed(error)
      @options[:status] = 403
      @message = error.message
    end

    def firebase_application_service_not_found(error)
      @options[:status] = 404
      @message = error.message
    end

    def google_cloud_already_exists_error(_error)
      @options[:status] = 422
      @message = "Record already exists"
    end

    def http_client_error(error)
      @options[:status] = error.status
      @message = error.parsed_body
    end

    def exception(error)
      @options[:status] = 500
      @message = "Sorry, there's an error on our side. We're working on it!"
      @message = error.message if @options[:debug]
    end
  end
end
