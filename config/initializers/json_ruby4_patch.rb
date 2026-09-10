# frozen_string_literal: true
#
# Compatibility patch: json gem 3.0 + Ruby 4
#
# json 3.0 changed JSON.parse to only accept keyword arguments after `source`.
# ActiveSupport::JSON.decode passes `options` as a positional hash argument,
# which raises ArgumentError in Ruby 4 on every request that reads an existing
# encrypted cookie (session, flash, CSRF token, etc.).
#
# This patch redefines ActiveSupport::JSON.decode to use ** (keyword splat).

module ActiveSupport
  module JSON
    class << self
      def decode(json, options = {})
        data = ::JSON.parse(json, **options)
        if ActiveSupport.parse_json_times
          convert_dates_from(data)
        else
          data
        end
      end
      alias_method :load, :decode
    end
  end
end
