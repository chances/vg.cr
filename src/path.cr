module VG
  enum PathCommand : UInt8
    # Empty path, end of path, or error
    Empty = 0
    # Start a new (sub) path
    Move = 1
    # Line
    Line = 2 | 128
    # Quadratic curve
    Quad = 3 | 128
    # Cubic bezier curve
    Cubic = 4 | 128

    # Size of a `PathCommand` in number of `Point`s.
    def self.size_of(command : PathCommand)
      case command
      when PathCommand::Empty
        0
      when PathCommand::Move
        1
      when PathCommand::Line
        1
      when PathCommand::Quad
        2
      when PathCommand::Cubic
        3
      end
    end
  end

  # A segment of a `Path`, i.e. a `PathCommand` and its relevant `Point` coordinates.
  struct PathSegment
    getter command : PathCommand
    getter points : Array(Point)

    def initialize(@command : PathCommand, @points : Array(Point))
    end

    # Get the `Point` at the given index.
    def [](i : Int) : Point
      @points[i]
    end

    # Get the `Point` at the given index, returning `nil` if the index is out of range.
    def []?(i : Int) : Point?
      @points[i]?
    end
  end

  # A 2D shape defined by a sequence of line or curve segments.
  # It can be open or closed, and can have multiple sub paths.
  #
  # ```
  # path = Path.new
  # path.moveTo(0, 0)
  # path.lineTo(10, 10)
  # path.quadTo(20, 20, 30, 30)
  # path.close
  # ```
  #
  # Commands may be chained:
  # ```
  # path = Path.new.moveTo(0, 0).lineTo(10, 10).quadTo(20, 20, 30, 30).close
  # ```
  class Path
    include Iterable(PathSegment)

    @points = Array(Point).new 0
    @commands = Array(PathCommand).new 0
    @last_move : UInt64 = -1

    def initialize
    end

    def initialize(path : Iterable(PathSegment))
      self.append path
    end

    # Number of commands in this path.
    def size
      @commands.size
    end

    # Number of points in this path.
    def size_in_points
      @points.size
    end

    def move_to(point : Point)
      @commands.push PathCommand::Move
      @points.push point
      @last_move = size
      return self
    end

    def move_to(x : Scalar, y : Scalar)
      self.move_to Point.new x, y
    end

    private def assert_pen_is_placed
      raise "Pen has not been placed! Call `move_to` first." unless @last_move >= 0
    end

    def line_to(point : Point)
      assert_pen_is_placed
      @commands.push PathCommand::Line
      @points.push point
      return self
    end

    def line_to(x : Scalar, y : Scalar)
      self.line_to Point.new x, y
    end

    # Close the current subpath. This draws a line back to the previous move command.
    def close
      assert_pen_is_placed
      self.line_to @points[@last_move]
    end

    def quad_to(a : Point, b : Point)
      assert_pen_is_placed
      @commands.push PathCommand::Quad
      @points.push a
      @commands.push PathCommand::Quad
      @points.push b
      return self
    end

    def quad_to(x1 : Scalar, y1 : Scalar, x2 : Scalar, y2 : Scalar)
      self.quad_to Point.new(x1, y1), Point.new(x2, y2)
    end

    def cubic_to(a : Point, b : Point, c : Point)
      assert_pen_is_placed
      @commands.push PathCommand::Cubic
      @points.push a
      @commands.push PathCommand::Cubic
      @points.push b
      @commands.push PathCommand::Cubic
      @points.push c
      return self
    end

    # The coordinates of the last move `Point`, i.e. the start of current sub path.
    def last_move_to
      assert_pen_is_placed
      @last_move
    end

    def reset
      @commands.clear
      @points.clear
      @last_move = -1
      return self
    end

    # Get the `PathSegment` at the given command index.
    def [](i : Int) : PathSegment
      command = @commands[i]
      points_start_index = @commands[..i].sum { |cmd| PathCommand.size_of cmd }
      points_end_index = points_start_index + PathCommand.size_of(command)
      points = @points[points_start_index..points_end_index]
      return PathSegment.new command, points
    end

    # Get the `Point` at the given index.
    def point_at(i : Int)
      @points[i]
    end

    # Get an array of this path's segments, i.e. its commands and the relevant `Point` coordinates for each `PathCommand`.
    def [](slice : Range) : Array(PathSegment)
      assert_pen_is_placed
      unless range.begin >= 0 && range.end < @commands.size - (range.excludes_end? ? 1 : 0)
        raise IndexError.new "Given slice range is out of bounds"
      end
      return @commands.map_with_index do |_, i|
        return self[i]
      end
    end

    def each : PathIterator
      PathIterator.new self
    end

    def append(path : Iterable(PathSegment))
      path.each_with_index do |segment, i|
        @commands.push segment.command
        segment.points.each { |point| @points.push point }
        @last_move = i if @commands[i] == PathCommand::Move
      end
    end

    # Offset this path by the given `delta`.
    def offset(delta : Point) : Path
      Path.new self.each.map do |segment|
        PathSegment.new segment.command, segment.points.map { |point| point + delta }
      end
    end

    def offset(delta_x : Scalar, delta_y : Scalar) : Path
      self.offset Point.new(delta_x, delta_y)
    end

    # Scale this path by the given `factor`.
    def scale(factor : Point) : Path
      Path.new self.each.map do |segment|
        PathSegment.new segment.command, segment.points.map { |point| point * factor }
      end
    end

    def scale(factor_x : Scalar, factor_y : Scalar) : Path
      self.scale Point.new(factor_x, factor_y)
    end

    # Scale this path relative to the given `focus`.
    def scale(factor : Point, focus : Point) : Path
      Path.new self.each.map do |segment|
        PathSegment.new segment.command, segment.points.map do |point|
          Point.new(
            (point.x - focus.x) * factor.x + focus.x,
            (point.y - focus.y) * factor.y + focus.x,
          )
        end
      end
    end

    def scale(factor_x : Scalar, factor_y : Scalar, focus : Point) : Path
      self.scale Point.new(factor_x, factor_y), focus
    end

    def scale(factor_x : Scalar, factor_y : Scalar, focus_x : Scalar, focus_y : Scalar) : Path
      self.scale Point.new(factor_x, factor_y), Point.new(focus_x, focus_y)
    end

    # This path in reverse.
    def retro : Path
      Path.new self.each.to_a.reverse
    end

    # This path in reverse.
    def reverse : Path
      self.retro
    end

    # TODO: Implement rotate: https://github.com/cerjones/dg2d/blob/f30334722a85a93d1426ab6585bf8ea2a1164c2a/source/dg2d/pathiterator.d#L322

    # Calculate the center of this path.
    #
    # Calculated by first calculating this path's bounding box `bounds` and returning
    # its center (`Rectangle.center`).
    def center : Point
      bounds.center
    end

    # Calculate the bounding box of this path.
    def bounds : Rectangle
      bounds = Rectangle.new
      self[..size].each do |segment|
        bounds.x = Math.min bounds.x, segment.points.min_by(&.x)
        bounds.y = Math.min bounds.y, segment.points.min_by(&.y)
        bounds.width = Math.max bounds.width, segment.points.max_by(&.x)
        bounds.height = Math.max bounds.height, segment.points.max_by(&.y)
      end
      return bounds
    end
  end

  class PathIterator
    include Iterator(PathSegment)

    getter path : Path

    def initialize(@path : Path)
      @index = 0
      @size = @path.size
    end

    def next
      if @index < @size
        @index += 1
        @path[@index]
      else
        stop
      end
    end
  end
end
