require 'minitest/autorun'
require 'minitest-colorize'
require "trusted_keys"
require 'ostruct'

Kernel.instance_eval do
  alias_method :context, :describe
end
