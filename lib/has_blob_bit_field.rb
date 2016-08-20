require "active_model"
require_relative "has_blob_bit_field/version"
require_relative "has_blob_bit_field/accessor"
require_relative "has_blob_bit_field/extension"

module ActiveModel::Dirty
  include HasBlobBitField::Extension
end
