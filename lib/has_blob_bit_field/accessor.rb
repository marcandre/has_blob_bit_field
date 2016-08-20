module HasBlobBitField
  class Accessor
    attr_reader :record, :column

    def initialize record, column
      @record = record
      @column = column
    end

    def [](index)
      index = check_index(index)
      val = byte(index)
      val & flag(index) != 0
    end

    def []=(index, set)
      index = check_index(index)
      set = !!set # force to true/false
      val = byte(index)
      mask = flag(index)
      if (val & mask != 0) != set
        notify_of_mutation
        raw_value.setbyte(index >> 3, val ^ mask)
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
          s << Array.new(size_in_bytes - s.size, 0).pack('C*')
        end
      end
      size_in_bits
    end

    alias_method :length, :size
    alias_method :length=, :size=

    def raw_value(init_nil: false)
      @record.public_send(@column) ||
        (init_nil && notify_of_mutation && @record.public_send(:"#{@column}=", ''.b)) ||
        ''.b
    end


  protected
    def notify_of_mutation
      @record.public_send :"#{@column}_will_change!"
      self
    end

    def flag(index)
      0b1000_0000 >> (index & 0b111)
    end

    def byte(index)
      raw_value.getbyte(index >> 3) || out_of_bound(index)
    end

    def check_index(index)
      out_of_bound(index) if index < 0
      index
    end

    def out_of_bound(index)
      raise IndexError, "#{index} is our of range for #{@column} which has size #{size}. Record: #{@record.inspect}}"
    end
  end
end

