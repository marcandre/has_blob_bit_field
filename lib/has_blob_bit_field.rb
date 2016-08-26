require "active_model"
require_relative "has_blob_bit_field/version"
require_relative "has_blob_bit_field/accessor"
require_relative "has_blob_bit_field/extension"

ActiveModel::Dirty.send :include, HasBlobBitField::Extension
ActiveRecord::Base.send :include, HasBlobBitField::Extension if defined? ActiveRecord
