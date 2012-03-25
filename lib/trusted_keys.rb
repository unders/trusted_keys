require 'trusted_keys/version'
require 'rails'
require 'trusted_keys/trustable'
require 'trusted_keys/error/usage'
require 'trusted_keys/error/not_trusted'

module TrustedKeys
  extend ActiveSupport::Concern

  module ClassMethods
    def trust(*args)
      options = args.extract_options!
      scope = options.fetch(:for, "").to_s.split '.'
      env = options[:env] || Rails.env
      nested = options.fetch(:nested, true)

      klass = Class.new do
        include Trustable
      end

      @_trusted_keys ||= []
      @_trusted_keys << klass.new(:scope => scope,
                                  :trusted_keys => @_trusted_keys,
                                  :untrusted => Error::NotTrusted.new(env),
                                  :nested => nested,
                                  :keys => args)
    end
  end

  private

  def trusted_attributes
    trusted_keys = self.class.instance_variable_get("@_trusted_keys")
    raise Error::Usage.new(params) unless trusted_keys

    sorted_keys = trusted_keys.sort

    attributes = sorted_keys.first.attributes(params)

    sorted_keys.drop(1).each do |trusted|
      current_attributes = trusted.on_scope(attributes)

      if trusted.parent_nested?
        current_attributes.each do |key, hash|
          hash[trusted.key] = trusted.attributes(hash)
        end
      else
        current_attributes[trusted.key] = trusted.attributes(current_attributes)
      end
    end

    attributes
  end
end
