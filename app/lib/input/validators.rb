# frozen_string_literal: true

module Input
  module Validators
    class NumberValidator < ActiveModel::Validations::NumericalityValidator
      def is_number?(raw_value, _precision, _scale)
        raw_value.is_a?(Numeric)
      end
    end

    class StringValidator < ActiveModel::EachValidator
      def validate_each(record, attr_name, value)
        opts = options.except(:format, :transform, :length)
        err = ->(type, options) { record.errors.add(attr_name, type, **options) }

        return err.call(:not_a_string, opts) unless value.is_a?(String)

        @transform.each { |t| value.public_send("#{t}!") }
        opts = opts.merge(value: value)

        err.call(:invalid, opts) if @format && value !~ @format

        length = value.length

        if @length.is_a?(Integer)
          (length == @length) || (return err.call(:wrong_length, **opts, count: @length))
        elsif @length.is_a?(Range)
          min, max = @length.minmax
          (length >= min) || (return err.call(:too_short, **opts, count: min))
          (length <= max) || (return err.call(:too_long, **opts, count: max))
        end
      end

      def check_validity!
        @format = options[:format]
        if @format && !@format.is_a?(Regexp)
          raise ArgumentError, "invalid :format option, must be a regexp"
        end

        @length = options[:length]
        if @length && !(@length.is_a?(Range) || @length.is_a?(Integer))
          raise ArgumentError, "invalid :length option, must be integer/range"
        end

        if @length.is_a?(Range) && !(@length.min && @length.max)
          raise ArgumentError, "invalid :length range option"
        end

        @transform = Array(options[:transform])
        invalids = @transform.reject { |t| "".methods.include?(:"#{t}!") }
        if invalids.any?
          methods = invalids.map { |t| "`#{t}!'" }
          raise ArgumentError,
                "invalid :transform option, String doesn't respond to #{methods}"
        end
      end
    end

    class ArrayValidator < ActiveModel::EachValidator
      def validate_each(record, attr_name, value)
        err = ->(type, opts) { record.errors.add(attr_name, type, opts) }
        each_type = options[:of] || options[:with]
        opts =
          options
          .except(:of, :with, :length)
          .merge(value: value, type: each_type)

        return err.call(:not_an_array, opts) unless value.is_a?(Array)

        return if !each_type || each_type == true

        unless value.all? { |v| v.is_a?(each_type) }
          return err.call(:invalid_element_type, opts)
        end

        length = value.length

        if @length.is_a?(Integer)
          (length == @length) || (return err.call(:wrong_length, **opts, count: @length))
        elsif @length.is_a?(Range)
          min, max = @length.minmax
          (length >= min) || (return err.call(:too_short, **opts, count: min))
          (length <= max) || (return err.call(:too_long, **opts, count: max))
        end
      end

      def check_validity!
        @length = options[:length]
        if @length && !(@length.is_a?(Range) || @length.is_a?(Integer))
          raise ArgumentError, "invalid :length option, must be integer/range"
        end

        if @length.is_a?(Range) && !(@length.min && @length.max)
          raise ArgumentError, "invalid :length range option"
        end
      end
    end

    class HashNestedValidator < ActiveModel::EachValidator
      def validate_each(record, attr_name, _value)
        model = record.public_send(attr_name)
        return true if model.valid?

        if options[:deep]
          copy_attr_errors(record, attr_name, model)
        else
          record.errors.add(attr_name, :invalid, **options.merge(value: model))
        end
      end

      def copy_attr_errors(record, attr_name, value)
        value.errors.attribute_names.each do |child_attr_name|
          attr_chain = attr_name.to_s
          attr_chain << ".#{child_attr_name}" if child_attr_name != :base
          attr_chain = attr_chain.to_sym

          value.errors.messages[child_attr_name].each do |error|
            record.errors.add(attr_chain, error)
            # record.errors.messages[attr_chain].dup!
            # record.errors.messages[attr_chain] ||= []
            # record.errors.messages[attr_chain] << error
            # record.errors.messages[attr_chain].uniq!
          end

          next unless value.errors.respond_to?(:details)

          value.errors.details[child_attr_name].each do |error|
            record.errors.add(attr_chain, error)
            # record.errors.details[attr_chain] ||= []
            # record.errors.details[attr_chain] << error
            # record.errors.details[attr_chain].uniq!
          end
        end
      end
    end

    class HashArrayValidator < HashNestedValidator
      def validate_each(record, attr_name, value)
        err = ->(type, opts) { record.errors.add(attr_name, type, **opts) }

        opts = options.merge(value: value, type: "object")
        return err.call(:not_an_array, **opts) unless value.is_a?(Array)
        return err.call(:blank, **opts) if value.blank?

        model = record.public_send(attr_name)
        return true if model.reject(&:valid?).empty?

        if options[:deep]
          model.each_with_index do |m, i|
            copy_attr_errors(record, "#{attr_name}[#{i}]", m)
          end
        else
          err.call(:invalid, **options.merge(value: model))
        end
      end
    end
  end
end
