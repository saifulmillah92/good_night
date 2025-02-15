# frozen_string_literal: true

module V1
  class ResourceController < ::ApplicationController
    before_action :initialize_global_limit_offset_variable!

    def index
      result = service.all(params)
      render_json_array result,
                        default_output,
                        use: format,
                        current_user: current_user,
                        total: total_count
    end

    def show
      result = service.find(params[:id])
      render_json result,
                  default_output,
                  current_user: current_user,
                  show: true,
                  use: show_format
    end

    def create
      result = service.create(permitted_params(:create))
      render_json result,
                  default_output,
                  status: :created,
                  current_user: current_user,
                  use: show_format
    end

    def update
      result = service.update(params[:id], permitted_params(:update))
      render_json result,
                  default_output,
                  current_user: current_user,
                  use: show_format
    end

    def destroy
      result = service.destroy(params[:id])
      render_json result,
                  default_output,
                  current_user: current_user,
                  use: show_format
    end

    private

    def default_output
      return Outputs::Api unless class_exists?("#{version}::#{model_class}Output")

      "#{version}::#{model_class}Output".constantize
    end

    def format
      :format
    end

    def show_format
      :full_format
    end

    def total_count
      service.count(params.except(:limit, :offset, :page))
    end

    def model_class
      controller_name.classify.to_s.constantize
    end

    def object_name
      controller_name.singularize
    end

    def service
      "#{model_class}Service".constantize.new(current_user)
    end

    def creation_input
      return unless class_exists?("#{version}::#{model_class}CreationInput")

      "#{version}::#{model_class}CreationInput".constantize
    end

    def update_input
      return unless class_exists?("#{version}::#{model_class}UpdateInput")

      "#{version}::#{model_class}UpdateInput".constantize
    end

    def permitted_params(method)
      input = input_method(method)
      return modified_request_body unless input.respond_to?(:new)

      input = input.new(modified_request_body)
      validate! input
      input.output
    end

    def input_method(method)
      case method
      when :create then creation_input
      when :update then update_input
      end
    end

    def modified_request_body
      request_body
    end
  end
end
