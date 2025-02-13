# frozen_string_literal: true

module Input
  class RequiredBuilder < Input::OptionalBuilder
    private def check_default(opts)
      return opts unless opts.key?(:default)

      raise ArgumentError, "default is not allowed for required attributes"
    end
  end
end
