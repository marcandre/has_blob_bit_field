require 'active_support'

module HasBlobBitField
  module Extension
    extend ActiveSupport::Concern

    class_methods do
      def has_blob_bit_field field, column: :"#{field}_blob"
        class_eval <<-EVAL, __FILE__, __LINE__
          def #{field}
            Accessor.new self, :#{column}
          end

          def #{field}=
            raise "Don't set the pseudo field #{field} directly, use []= on it"
          end
        EVAL
      end
    end

  end
end
