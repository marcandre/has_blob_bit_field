module HasBlobBitField
  module Extension
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def has_blob_bit_field field, column: :"#{field}_blob"
        class_eval <<-EVAL, __FILE__, __LINE__
          def #{field}
            @_#{field}_accessor ||= Accessor.new self, :#{column}
          end

          def #{field}=(values)
            #{field}.replace(values)
          end
        EVAL
      end
    end

  end
end
