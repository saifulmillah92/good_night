# frozen_string_literal: true

# ApplicationRepository
class ApplicationRepository < Repositories::Base
  DEFAULT_LIMIT = 10
  DEFAULT_OFFSET = 0

  def include?(id)
    @scope.exists?(id)
  end

  def new(params = {})
    @scope.unscoped.new(params)
  end

  def get(id)
    load(@scope.where(id: id).unscope(:limit))[0]
  end

  def name
    @scope.klass.model_name.human
  end

  def limited
    filter(limit: @scope.limit_value)
  end

  private

  def column(name)
    case_insensitive = ["1", 1, "true", true].include? @options[:case_insensitive]
    type = @scope.columns_hash[name.to_s].type
    return @scope.arel_table[name].lower if type == :string && case_insensitive

    @scope.arel_table[name]
  end

  def filter_by_limit(limit)
    limit = (limit || DEFAULT_LIMIT).to_i
    @scope.limit(limit)
  end

  def filter_by_offset(offset)
    offset = (offset || DEFAULT_OFFSET).to_i
    @scope.offset(offset)
  end

  def filter_by_page(page)
    return @scope.offset(DEFAULT_OFFSET) unless page.to_i > 1

    offset = (@options["limit"].to_i * (page.to_i - 1))
    @scope.offset(offset)
  end

  def filter_by_next_cursor(cursor_id)
    validate_cursor_value!(:next_cursor, cursor_id)
    value = find_sort_column_cursor_value(cursor_id)

    case sort_direction
    when "asc" then next_asc(value, cursor_id)
    when "desc" then next_desc(value, cursor_id)
    end
  end

  def filter_by_prev_cursor(cursor_id)
    validate_cursor_value!(:prev_cursor, cursor_id)
    value = find_sort_column_cursor_value(cursor_id)

    result = if sort_direction == "asc"
               next_desc(value, cursor_id).reorder(order_desc(sort_column))
             else
               next_asc(value, cursor_id).reorder(order_asc(sort_column))
             end

    @scope.where(id: result.select(:id))
  end

  def find_sort_column_cursor_value(cursor_id)
    validate_sort_column!(sort_column)

    cursor_record = @scope.find_by(id: cursor_id)
    cursor_record.send(sort_column)
  end

  def next_asc(cursor_value, id)
    @scope.where(
      "(#{sort_column} > ?) OR (#{sort_column} = ? AND id > ?)",
      cursor_value,
      cursor_value,
      id,
    )
  end

  def next_desc(cursor_value, id)
    @scope.where(
      "(#{sort_column} < ?) OR (#{sort_column} = ? AND id < ?)",
      cursor_value,
      cursor_value,
      id,
    )
  end

  def filter_by_id(id)
    @scope.where(id: Id[id])
  end

  def truthly?(truthly)
    truthly.in?(["true", 1, true])
  end

  # Sortable
  module Sortable
    def self.included(base)
      def base.sort_by(column, direction)
        column = column.to_s
        direction = direction.to_s
        raise StandardError, "sort direction must be asc/desc" \
          unless ["asc", "desc"].include?(direction)

        @sort_column = column
        @sort_direction = direction
      end
    end

    private

    def default_options
      {
        sort_column: self.class.instance_variable_get(:@sort_column),
        sort_direction: self.class.instance_variable_get(:@sort_direction),
      }
    end

    def filter_by_sort_column(sort_column)
      validate_sort_column!(sort_column)

      case sort_direction
      when "asc" then @scope.reorder(order_asc(sort_column))
      when "desc" then @scope.reorder(order_desc(sort_column))
      end
    end

    def validate_sort_column!(sort_column)
      return if sort_column.blank?

      validate_column = @scope.column_names.include?(sort_column.to_s)

      invalid = ActiveModel::StrictValidationFailed
      error_message = "Column #{sort_column} does not exist"
      raise invalid, error_message unless validate_column
    end

    def validate_cursor_value!(key, value)
      raise ArgumentError, "#{key} cannot be blank" if value.blank?

      message = "you cannot add both values on next and prev cursor"
      both_present = @options[:prev_cursor].present? && @options[:next_cursor].present?
      raise ArgumentError, message if both_present
    end

    def order_asc(order_column)
      id_asc = column("id").asc
      return id_asc if order_column.to_s == "id"

      order_nulls = order_nulls_value || "NULLS FIRST"
      Arel.sql("#{column(order_column).asc.to_sql} #{order_nulls}, #{id_asc.to_sql}")
    end

    def order_desc(order_column)
      id_desc = column("id").desc
      return id_desc if order_column.to_s == "id"

      order_nulls = order_nulls_value || "NULLS LAST"
      Arel.sql("#{column(order_column).desc.to_sql} #{order_nulls}, #{id_desc.to_sql}")
    end

    def order_nulls_value
      order_nulls = @options[:order_nulls] || @options["order_nulls"]
      return nil if order_nulls.blank?

      order_nulls == "first" ? "NULLS FIRST" : "NULLS LAST"
    end

    def sort_column
      @options[:sort_column] || @options["sort_column"]
    end

    def sort_direction
      @options[:sort_direction] || @options["sort_direction"]
    end
  end

  include Sortable
end
