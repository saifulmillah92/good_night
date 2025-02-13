# frozen_string_literal: true

module Input
  module Validatable
    extend ActiveSupport::Concern
    include ActiveModel::Validations
    include Input::Data

    def read_attribute_for_validation(name)
      self[name]
    end

    private def run_validations!
      if @attributes.is_a?(Hash)
        super
      else
        errors.add(:base, :not_a_hash)
        false
      end
    end

    module ClassMethods
      def on_unknown_attributes(do_what)
        case do_what
        when :invalidate then invalidate_unknown_attributes
        when :strip then strip_unknown_attributes
        when :ignore then nil
        else raise ArgumentError, "invalid arg #{do_what}"
        end
      end

      def invalidate_unknown_attributes
        validate do
          @attributes.each do |name, _|
            errors.add(name, :unknown) unless keys[name]
          end
        end
      end

      def strip_unknown_attributes
        define_method :apply_aliases do |hash|
          super(hash).select { |name, _| keys[name] }
        end
      end
    end
  end
end
