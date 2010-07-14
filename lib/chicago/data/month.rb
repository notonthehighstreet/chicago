module Chicago
  module Data
    # A month of the year.
    #
    # Months cannot be initialized. Instead call the month name:
    #
    #     Chicago::Data::Month.march # => returns a month
    #
    # or parse a string or a month number:
    #
    #     Chicago::Data::Month.parse("apr")       # => returns April
    #     Chicago::Data::Month.parse("september") # => returns September
    #     Chicago::Data::Month.parse(1)           # => returns January
    #
    class Month
      include Comparable

      # Returns the full English name of this month
      attr_reader :name

      # Returns the first three letters of the English name of this month.
      attr_reader :short_name

      def initialize(name, number)
        @name = name
        @short_name = name[0..2]
        @number = number
      end

      def <=>(other)
        to_i <=> other.to_i 
      end

      # Returns the first day of this month in the given year as a Date.
      def in(year)
        Date.new(year, to_i, 1)
      end

      # Returns the number of this month from 1 to 12.
      def to_i
        @number
      end

      # Returns the full name of this month.
      def to_s
        name
      end

      # All twelve months.
      ALL = [Month.new("January", 1),
             Month.new("February", 2),
             Month.new("March", 3),
             Month.new("April", 4),
             Month.new("May", 5),
             Month.new("June", 6),
             Month.new("July", 7),
             Month.new("August", 8),
             Month.new("September", 9),
             Month.new("October", 10),
             Month.new("November", 11),
             Month.new("December", 12)].freeze

      class << self
        [:january, :february, :march, :april, :may, :june, :july, :august, :september, :october, :november, :december].each_with_index do |month, i|
          eval "def #{month} ; ALL[#{i}] ; end"
        end

        # Returns a month given a name of the month or an integer
        # between 1 and 12.
        def parse(identifier)
          if identifier.kind_of?(Fixnum) && identifier >= 1 && identifier <= 12
            ALL[identifier - 1]
          else
            name = identifier.strip.downcase
            ALL.find {|month| month.name.downcase == name || month.short_name.downcase == name }
          end
        end

        private :new
      end
      
    end
  end
end
