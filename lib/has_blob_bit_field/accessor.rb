module HasBlobBitField
  class Accessor
    include Enumerable
    include Comparable
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

    def replace(values)
      new_raw_value = if values.class == self.class
        values.raw_value
      else
        masks = (0..7).map {|i| flag(i) }
        self.size = values.size
        values.each_slice(8).map do |flags|
          flags.each_with_index.inject(0) do |sum, (flag, bit_number)|
            sum | (flag ? masks[bit_number] : 0)
          end
        end.pack('C*')
      end
      replace_raw_value new_raw_value
      self
    end

    def each
      return to_enum unless block_given?
      masks = (0..7).map {|i| flag(i) }
      raw_value.each_byte do |byte|
        masks.each do |mask|
          yield mask & byte != 0
        end
      end
      self
    end

    def map!
      return to_enum unless block_given?
      replace(map {|b| yield b })
    end

    def <=>(other)
      value_method = (other.class == self.class ? :raw_value : :to_a)
      public_send(value_method) <=> other.public_send(value_method)
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
      if true != value && false != value
        raise TypeError
      end
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

