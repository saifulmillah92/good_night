# frozen_string_literal: true

module Outputs
  class Array < Outputs::Api
    def self.root_key
      true
    end

    def initialize(*args)
      super
      @object = Array(@object)
    end

    def as_root_json
      json = {
        code: @options[:status],
        message: @options[:message],
        root_key => outputs,
        **pagination,
      }

      json.merge!(@options[:metadata]) unless @options[:metadata].nil?
      json.as_json
    end

    def format
      outputs
    end

    def outputs
      @outputs ||= @object.map { |o| item_output.new(o, item_options) }
    end

    def item_options
      @options.except(:item_output, :cursor, :root, :status)
    end

    def root_key
      @options.fetch(:root) { item_output.root_key }
    end

    def item_output
      @options[:item_output]
    end

    def total
      @options[:total]
    end

    def limit
      Current.limit
    end

    def offset
      Current.offset
    end

    def current_page
      Current.page
    end

    def pagination_type
      Current.pagination_type
    end

    def sort_direction
      Current.sort_direction
    end

    def sort_column
      Current.sort_column
    end

    def pagination
      {
        **offset_pagination,
        **page_pagination,
        **cursor_pagination,
      }
    end

    def offset_pagination
      return {} unless pagination_type == "offset_pagination"

      {
        total: total,
        pagination: {
          limit: limit,
          current_offset: offset,
          next_offset: next_offset,
          prev_offset: prev_offset,
        },
      }
    end

    def page_pagination
      return {} unless pagination_type == "page_pagination"

      {
        pagination: {
          current_page: current_page,
          next_page: next_page,
          prev_page: prev_page,
          total_pages: total_pages,
        },
      }
    end

    def cursor_pagination
      return {} unless pagination_type == "cursor_pagination"

      {
        pagination: {
          next_cursor: next_cursor&.id,
          prev_cursor: prev_cursor&.id,
        },
      }
    end

    def next_cursor
      return @object.last if sort_column == "id"
      return nil if @object.size < limit || @object.blank?

      key = sort_direction == "asc" ? :max : :min
      find_cursor(key)
    end

    def prev_cursor
      return @object.last if sort_column == "id"
      return nil if @object.blank?

      key = sort_direction == "asc" ? :min : :max
      find_cursor(key)
    end

    def find_cursor(key)
      @data ||= @object.group_by { |a| a.send(sort_column) }
      target_value = @object.pluck(sort_column.to_sym).send(key)
      @data[target_value].send(key)
    end

    def next_offset
      (offset + limit) >= total ? nil : offset + limit
    end

    def prev_offset
      offset > limit ? offset - limit : 0
    end

    def total_pages
      (total.to_f / limit).ceil
    end

    def next_page
      current_page < total_pages ? current_page + 1 : nil
    end

    def prev_page
      current_page > 1 ? current_page - 1 : nil
    end

    def error?
      outputs.any?(&:error?)
    end

    def error_format
      Outputs::Error.new(error_messages, status: error_status)
    end

    def error_messages
      outputs.each_with_index.map do |output, index|
        output.error_format.as_json.reverse_merge(index: index)
      end
    end
  end
end
