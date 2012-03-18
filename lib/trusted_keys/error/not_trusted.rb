module TrustedKeys
  module Error
    class NotTrusted < StandardError
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

      def production?
        not(Rails.env.development? or Rails.env.test?)
      end
    end
  end
end
