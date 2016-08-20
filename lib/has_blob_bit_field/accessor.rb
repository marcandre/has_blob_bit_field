module HasBlobBitField
  class Accessor
    attr_reader :record, :column

    def initialize record, column
      @record = record
      @column = column
    end

    def [](bit_index)
      bit_index = check_index(bit_index)
      val = byte(bit_index)
      val & flag(bit_index) != 0
    end

    def []=(bit_index, set)
      bit_index = check_index(bit_index)
      set = coerce_to_bool(set)
      val = byte(bit_index)
      mask = flag(bit_index)
      was_set = val & mask != 0
      if was_set != set
        notify_of_mutation
        raw_value.setbyte(bit_index >> 3, val ^ mask)
      end
      set
    end

    def size
      raw_value.size << 3
    end

    def size=(size_in_bits)
      raise IndexError unless size_in_bits >= 0
      size_in_bytes = (size_in_bits + 7) >> 3
      s = raw_value(init_nil: true)

      if s.size != size_in_bytes
        notify_of_mutation
        if s.size > size_in_bytes
          s[size_in_bytes..s.size] = ''
        else
          s << "\0".b * (size_in_bytes - s.size)
        end
      end
      size_in_bits
    end

    alias_method :length, :size
    alias_method :length=, :size=

    def raw_value(init_nil: false)
      @record.public_send(@column) ||
        (init_nil && replace_raw_value(''.b)) ||
        ''.b
    end


  protected
    def notify_of_mutation
      @record.public_send :"#{@column}_will_change!"
      self
    end

    def replace_raw_value(raw)
      notify_of_mutation
      @record.public_send(:"#{@column}=", raw)
    end

    def flag(bit_index)
      0b1000_0000 >> (bit_index & 0b111)
    end

    def byte(bit_index)
      raw_value.getbyte(bit_index >> 3) || out_of_bound(bit_index)
    end

    def coerce_to_bool(value)
      raise TypeError unless value == true || value == false
      value
    end

    def check_index(bit_index)
      out_of_bound(bit_index) if bit_index < 0
      bit_index
    end

    def out_of_bound(bit_index)
      raise IndexError, "#{bit_index} is our of range for #{@column} which has size #{size}. Record: #{@record.inspect}}"
    end
  end
end

