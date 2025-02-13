# frozen_string_literal: true

module Input
  module HasAliases
    extend ActiveSupport::Concern

    included do
      @aliases = {}
    end

    def apply_aliases(hash)
      aliases = self.class.aliases
      hash
        .reject { |k| hash.key?(aliases[k]) }
        .transform_keys { |k| aliases[k] || k }
    end

    module ClassMethods
      def inherited(base)
        super
        base.instance_variable_set("@aliases", aliases)
      end

      def aliases
        @aliases.dup
      end

      def alias_key(alias_name, target_name)
        @aliases[alias_name.to_sym] = target_name.to_sym
        @aliases[alias_name.to_s] = target_name.to_sym
      end
    end
  end

  class Plugin
    def initialize(name, defn)
      @name = name
      @defn = defn
    end

    def call(object)
      object.define_singleton_method(@name, &@defn)
    end
  end
end
