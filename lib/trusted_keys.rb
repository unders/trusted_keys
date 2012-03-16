require 'trusted_keys/version'
require 'rails'
require 'trusted_keys/trustable'
require 'trusted_keys/error/usage'

module TrustedKeys
  extend ActiveSupport::Concern

  module ClassMethods
    def trust(*args)
      scope = args.extract_options!.fetch(:for, "").to_s.split '.'

      klass = Class.new do
        include Trustable
        send("attr_accessible", *args)
      end

      @_trusted_keys ||= []
      @_trusted_keys << klass.new(scope, @_trusted_keys, *args)
    end
  end

  private

  def trusted_attributes
    trusted_keys = self.class.instance_variable_get("@_trusted_keys")
    raise Error::Usage.new(params) unless trusted_keys

    sorted_keys = trusted_keys.sort

    attributes = sorted_keys.first.attributes(params)

    sorted_keys.drop(1).each do |trusted|
      trusted.on_scope(attributes)[trusted.key] = trusted.attributes(params)
    end

    attributes
  end
end
