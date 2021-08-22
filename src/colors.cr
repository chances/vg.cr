module VG
  record Color, r : UInt8, g : UInt8, b : UInt8, a : Float32 do
    def initialize(@r : UInt8, @g : UInt8, @b : UInt8, @a : Float32 = 1)
      raise RangeError.new "Red component is out of bounds" unless @r >= 0 && @r <= 255
      raise RangeError.new "Green component is out of bounds" unless @g >= 0 && @g <= 255
      raise RangeError.new "Blue component is out of bounds" unless @b >= 0 && @b <= 255
      raise RangeError.new "Alpha component is out of bounds" unless @a >= 0 && @a <= 1
    end

    def initialize(color : UInt32)
      @r = ((color & 0xFF0000) >> 16).to_u8
      @g = ((color & 0x00FF00) >> 8).to_u8
      @b = (color & 0x0000FF).to_u8
      @a = 1
    end

    # TODO: https://github.com/chances/teraflop-d/blob/3746d3813556ff55b538e7bcd91ebe1e86679253/source/teraflop/graphics/package.d#L84
    # def self.hsv(hue : Int, saturation : Float32, value : Float32)
    # end

    # Adjust a `Color`s alpha channel, setting it to the given percentage.
    # Raises: A `RangeError` if the given `alpha` component is outside the range `0.0` through `1.0`.
    def with_alpha(alpha : Float32)
      raise RangeError.new "Alpha component is out of bounds" unless alpha >= 0 && alpha <= 1
      self.new @r, @g, @b, alpha
    end

    def to_u32
      (@r << 16) + (@g << 8) + @b
    end

    def to_css
      return "rgba(#{@r},#{@g},#{@b},#{(@a / 255.0 * 100).round}%)" if @a < 1
      return "#" + sprintf("%X", self.to_u32).pad_left('0', 6)
    end
  end

  module Colors
    TRANSPARENT = Color.new 0, 0, 0, 0
    BLACK       = Color.new 0x0
    WHITE       = Color.new 0xFFFFFF
  end
end
