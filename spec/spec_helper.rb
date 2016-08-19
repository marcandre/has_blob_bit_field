$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'has_blob_bit_field'
require 'rspec/its'
require 'pry'

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
end
