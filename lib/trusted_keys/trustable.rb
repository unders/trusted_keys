require 'trusted_keys/error/not_trusted'

module TrustedKeys
  module Trustable
    extend ActiveSupport::Concern
    include ActiveModel::MassAssignmentSecurity
    attr_reader :keys

    def initialize(scope, trusted_keys, *keys)
      @scope = scope
      @trusted_keys = trusted_keys
      @keys = keys
    end

    def attributes(params)
      params = @scope.inject(params) { |params, key| params[key] }
      result = sanitize_for_mass_assignment(params)

      keys = params.keys(&:to_s) - result.keys.map(&:to_s)

      unless keys.empty?
        not_trusted =  Error::NotTrusted.new.keys(:scope => @scope,
                                                  :key => nil,
                                                  :keys => keys)

        raise not_trusted if not_trusted.present?
      end

      remove_untrusted_keys(result)
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

    def remove_untrusted_keys(attributes)
      trusted_keys = @trusted_keys.select do |trusted|
        trusted.level == (level + 1)
      end.map { |trusted| trusted.key.to_s }

      not_trusted =  Error::NotTrusted.new

      attributes.each do |key, value|
        if value.is_a?(Hash) and !trusted_keys.include?(key.to_s)
          attributes[key] = ""
          not_trusted.keys :scope => @scope, :key => key, :keys => value.keys
        end
      end

      raise not_trusted if not_trusted.present?

      attributes
    end
  end
end
