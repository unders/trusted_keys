require 'trusted_keys/version'
require 'rails'
require 'trusted_keys/trustable'

module TrustedKeys
  extend ActiveSupport::Concern

  class UsageError < StandardError
    def initialize(params)
      @params = params
    end

    def message
      "\n\nparams => #{@params.inspect}\n\n" +
      "Error: Before using `trusted_attributes` you must set the " +
      "trusted keys in the controller, for examples: `trust :post` " +
      "or `trust :title, :body, for: 'post'`"
    end
  end

  class NotTrustedError < StandardError
    def initialize
      @keys = {}
    end

    def message
      usage = @keys.map do |scope, keys|
        "`trust #{keys}, for: '#{scope}'`"
      end.join("\n")

      "\n\nError: There are keys in the params hash that are not trusted. " +
      "Set them as trusted with:\n#{usage} at the top of the controller."
    end

    def keys(options)
      scope = options.fetch(:scope)
      key = options.fetch(:key)
      keys = options.fetch(:keys).flatten.map do |key|
        ":#{key.sub(/\(\di\)/, '')}"
      end.uniq.join(', ')

      scope_key = (scope + [key]).compact.join('.')
      @keys[scope_key] = keys unless scope_key.empty?

      self
    end

    def present?
      if production?
        false
      else
        not @keys.empty?
      end
    end

    private

    def production?
      not(Rails.env.development? or Rails.env.test?)
    end
  end

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
    raise UsageError.new(params) unless trusted_keys

    sorted_keys = trusted_keys.sort

    attributes = sorted_keys.first.attributes(params)

    sorted_keys.drop(1).each do |trusted|
      trusted.on_scope(attributes)[trusted.key] = trusted.attributes(params)
    end

    attributes
  end
end
