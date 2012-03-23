require 'active_support/core_ext/hash/indifferent_access'

module TrustedKeys
  module Trustable
    extend ActiveSupport::Concern
    include ActiveModel::MassAssignmentSecurity

    def initialize(options)
      @scope = options.fetch(:scope)
      @trusted_keys = options.fetch(:trusted_keys)
      @untrusted = options.fetch(:untrusted)
      @nested = options[:nested] || false

      self.class.send("attr_accessible", *options.fetch(:keys))
    end

    def attributes(params)
      params = @scope.inject(params) do |params, key|
        params[key.to_sym] || params[key.to_s]
      end

      if @nested
        {}.tap do |hash|
          params.each do |key, nested_hash|
            hash[key] = sanitize(nested_hash)
          end
        end
      else
        sanitize(params)
      end
    end

    def on_scope(attributes)
      @scope.slice(1, @scope.size - 2).reduce(attributes) do |attributes, key|
        attributes[key]
      end
    end

    def key; @key ||= @scope.last; end
    def <=> (other); level <=> other.level; end
    def level; @scope.size; end

    private

    def sanitize(params)
      result = sanitize_for_mass_assignment(params)

      keys = params.keys.map(&:to_s) - result.keys.map(&:to_s)

      unless keys.empty?
        untrusted = @untrusted.keys(:scope => @scope,
                                    :key => nil,
                                    :keys => keys)
        raise untrusted if untrusted.present?
      end

      remove_untrusted_keys(result)
    end

    def remove_untrusted_keys(attributes)
      trusted_keys = @trusted_keys.select do |trusted|
        trusted.level == (level + 1)
      end.map { |trusted| trusted.key.to_s }

      attributes.each do |key, value|
        if value.is_a?(Hash) and !trusted_keys.include?(key.to_s)
          attributes[key] = ""
          @untrusted.keys :scope => @scope, :key => key, :keys => value.keys
        end
      end

      raise @untrusted if @untrusted.present?

      HashWithIndifferentAccess.new(attributes)
    end
  end
end
