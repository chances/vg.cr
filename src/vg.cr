require "./colors"

module VG
  alias Scalar = Float64

  record Point, x : Scalar, y : Scalar do
    def initialize(@x : Scalar, @y : Scalar)
    end

    def self.origin : Point
      Point.new(0, 0)
    end

    def - : Point
      Point.new(-@x, -@y)
    end

    def +(other : self) : Point
      Point.new(@x + other.x, @y + other.y)
    end

    def -(other : self) : Point
      Point.new(@x - other.x, @y - other.y)
    end

    def *(other : self) : Point
      Point.new(@x * other.x, @y * other.y)
    end
  end

  alias Position = Point
  alias Radii = Point

  record Size, width : Scalar, height : Scalar do
    def initialize(width : Scalar, height : Scalar)
      @width = width
      @height = height
    end
  end

  record Rectangle, x : Scalar, y : Scalar, width : Scalar, height : Scalar do
    def initialize(position : Position, size : Size)
      @x = position.x
      @y = position.y
      @width = size.width
      @height = size.height
    end

    def initialize(@x : Scalar, @y : Scalar, @width : Scalar, @height : Scalar)
    end

    def position : Position
      Position.new x, y
    end

    def size : Size
      Size.new width, height
    end

    def top
      @y
    end

    def right
      @x + @width
    end

    def bottom
      @y + @height
    end

    def left
      @x
    end

    # Calculates the center of this rectangle.
    def center : Point
      Point.new(
        left + ((right - left) / 2),
        top + ((bottom - top) / 2),
      )
    end
  end

  record RoundRect, x : Scalar, y : Scalar, width : Scalar, height : Scalar, radii : Radii do
    def initialize(bounds : Rectangle, @radii : Radii)
      @x = bounds.x
      @y = bounds.y
      @width = bounds.width
      @height = bounds.height
    end

    def initialize(@x : Scalar, @y : Scalar, @width : Scalar, @height : Scalar, @radii : Radii)
    end

    def bounds
      Rectangle.new @x, @y, @width, @height
    end

    # X and Y radii
    def radii
      @radii
    end
  end

  class Canvas
    def initialize(size : Size)
      @width = size.width
      @height = size.height
    end

    def initialize(@width : Scalar, @height : Scalar)
    end
  end
end
