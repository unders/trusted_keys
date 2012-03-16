module TrustedKeys
  module Error
    class Usage < StandardError
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
  end
end
