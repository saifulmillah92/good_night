# frozen_string_literal: true

class ApplicationInput
  include ::Input

  COMMA = /\s*,\s*/

  plugin :datetime do |**opts|
    validates_each(opts) do |record, attr_name, value|
      if value.nil?
        record.errors.add(attr_name, :blank) unless opts[:allow_nil]
        next
      end

      if value.blank? && !opts[:allow_blank]
        record.errors.add(attr_name, :blank)
        next
      end

      time = value if value.is_a?(Time)

      begin
        time ||= Current.time_zone.parse(value)
      rescue TypeError, ArgumentError
        next record.errors.add(attr_name, :invalid)
      end
      next record.errors.add(attr_name, :invalid) if time.nil? && !value.nil?

      record[attr_name] = time
    end
  end

  plugin :comma_separated_string do |any_of = nil, **opts|
    validates_each(opts) do |record, attr_name, value|
      if value.is_a?(String)
        record[attr_name] = value.split(COMMA)
      elsif !value.is_a?(Array)
        record.errors.add(attr_name, :not_a_string)
        next
      end

      if any_of && (any_of & record[attr_name]).empty?
        record.errors.add(attr_name, :inclusion)
      end
    end
  end

  def valid?(*_)
    result = super
    @validated = true
    result
  end

  def valid
    valid? unless @validated
    yield(self) if errors.none?
    self
  rescue ActiveModel::StrictValidationFailed => e
    errors.add(:base, e.message)
    self
  rescue ActiveRecord::RecordInvalid => e
    copy_errors(e.record)
    self
  end

  def error
    valid? unless @validated
    yield(self) if errors.any?
    self
  end

  def copy_errors(model)
    model.errors.messages.each do |model_key, message|
      errors.add(model_key.to_sym, message: message)
    end
  end

  def ensure_validity(key)
    any_error = Array(send(key)).any? { |model| model.errors.any? }
    any_error && errors.add(key)
  end

  private def method_missing(name, *_, &block)
    keys[name] ? self[name] : super
  end

  private def respond_to_missing?(name, include_private = false)
    keys[name] || super
  end
end
