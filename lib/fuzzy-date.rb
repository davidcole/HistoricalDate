require 'date'

module FuzzyDate

  DATE_SEPARATOR = '[^A-Za-z0-9]'

  @month_names = {
    1 => 'January',
    2 => 'February',
    3 => 'March',
    4 => 'April',
    5 => 'May',
    6 => 'June',
    7 => 'July',
    8 => 'August',
    9 => 'September',
    10 => 'October',
    11 => 'November',
    12 => 'December'
    }

  @month_abbreviations = {
    'Jan' => 'January',
    'Feb' => 'February',
    'Mar' => 'March',
    'Apr' => 'April',
    'May' => 'May',
    'Jun' => 'June',
    'Jul' => 'July',
    'Aug' => 'August',
    'Sep' => 'September',
    'Oct' => 'October',
    'Nov' => 'November',
    'Dec' => 'December'
    }

  @days_in_month = {
    1 => 31,
    2 => 28,
    3 => 31,
    4 => 30,
    5 => 31,
    6 => 30,
    7 => 31,
    8 => 31,
    9 => 30,
    10 => 31,
    11 => 30,
    12 => 31
    }

  @range_words = [
    'Between',
    'Bet',
    'Bet.',
    'From'
    ]

  @middle_range_words = [
    # '-',  -  Not used because it is more commonly used as a delimiter
    'To',
    'And'
    ]

  @circa_words = [
    'Circa',
    'About',
    'Abt',
    'Abt.',
    '~'
    ]

  @era_words = [
    'AD',
    'BC',
    'CE',
    'BCE'
    ]

  # *Note*: This is only for single dates - not ranges.
  #
  # Possible incoming date formats:
  # * YYYY-MM-DD  -  starts with 3 or 4 digit year, and month and day may be 1 or 2 digits
  # * YYYY-MM  -  3 or 4 digit year, then 1 or 2 digit month
  # * YYYY  -  3 or 4 digit year
  # * MM-DD-YYYY  -  1 or 2 digit month, then 1 or 2 digit day, then 1 to 4 digit year
  # * DD-MM-YYYY  -  1 or 2 digit day, then 1 or 2 digit month, then 1 to 4 digit year if is_euro is true
  # * MM-YYYY  -  1 or 2 digit month, then 1 to 4 digit year
  # * DD-MMM  -  1 or 2 digit day, then month name or abbreviation
  # * DD-MMM-YYYY  -  1 or 2 digit day, then month name or abbreviation, then 1 to 4 digit year
  # * MMM-YYYY   -  month name or abbreviation, then 1 to 4 digit year
  # * MMM-DD-YYYY  -  month name or abbreviation, then 1 or 2 digit day, then 1 to 4 digit year
  #
  # Notes:
  # - Commas are optional.
  # - Delimiters can be most anything non-alphanumeric.
  # - All dates may be suffixed with the era (AD, BC, CE, BCE). AD is assumed.
  # - Dates may be prefixed by circa words (Circa, About, Abt).

  def self.parse_date( date, is_euro = false )

    date = clean_parameter date

    return '' if date == ''

    date_parts = set_up_date_parts date

    date_in_parts = []

    date_separator = Regexp.new DATE_SEPARATOR, true

    #- Split the string

    date_in_parts = date.split date_separator
    date_in_parts.delete_if { |d| d.to_s.empty? }
    if date_in_parts.first.match Regexp.new( @circa_words.join( '|' ), true )
      date_parts[ :circa ] = true
      date_in_parts.shift
    end
    if date_in_parts.last.match Regexp.new( @era_words.join( '|' ), true )
      date_parts[ :era ] = date_in_parts.pop.upcase.strip
    end

    date = date_in_parts.join '-'
    date_parts[ :fixed ] = date

    #- Takes care of YYYY
    if date =~ /^(\d{1,4})$/
      year = $1.to_i.to_s
      month = nil
      day = nil

    #- Takes care of YYYY-MM-DD and YYYY-MM
    elsif date =~ /^(\d{3,4})(?:-(\d{1,2})(?:-(\d{1,2}))?)?$/
      year = $1.to_i.to_s
      month = $2 ? $2.to_i.to_s : nil
      day = $3 ? $3.to_i.to_s : nil

    #- Takes care of DD-MM-YYYY
    elsif date =~ /^(\d{1,2})-(\d{1,2})-(\d{1,4})$/ and is_euro
      day = $1.to_i.to_s
      month = $2.to_i.to_s
      year = $3.to_i.to_s

    #- Takes care of MM-DD-YYYY
    elsif date =~ /^(\d{1,2})-(\d{1,2})-(\d{1,4})$/
      month = $1.to_i.to_s
      day = $2.to_i.to_s
      year = $3.to_i.to_s

    #- Takes care of MM-YYYY
    elsif date =~ /^(\d{1,2})-(\d{1,4})?$/
      month = $1.to_i.to_s
      day = nil
      year = $2.to_i.to_s

    #- Takes care of DD-MMM-YYYY and DD-MMM
    elsif date =~ /^(\d{1,2})(?:-(#{ @month_abbreviations.keys.join( '|' ) }).*?(?:-(\d{1,4}))?)?$/i
      month_text = $2.to_s.capitalize
      month = @month_names.key( @month_abbreviations[ month_text ] ).to_i.to_s
      day = $1.to_i.to_s
      year = $3 ? $3.to_i.to_s : nil

    #- Takes care of MMM-DD-YYYY
    elsif date =~ /^(#{ @month_abbreviations.keys.join( '|' ) }).*?-(\d{1,2})-(\d{1,4})$/i
      month_text = $1.to_s.capitalize
      month = @month_names.key( @month_abbreviations[ month_text ] ).to_i.to_s
      day = $2.to_i.to_s
      year = $3 ? $3.to_i.to_s : nil

    #- Takes care of MMM-YYYY and MMM
    elsif date =~ /^(#{ @month_abbreviations.keys.join( '|' ) }).*?(?:-(\d{1,4}))?$/i
      month_text = $1.to_s.capitalize
      month = @month_names.key( @month_abbreviations[ month_text ] ).to_i.to_s
      day = nil
      year = $2 ? $2.to_i.to_s : nil

    else
      raise ArgumentError.new( 'Cannot parse date.' )
    end

    date_parts[ :year   ] = year  ? year.to_i   : nil
    date_parts[ :month  ] = month ? month.to_i  : nil
    date_parts[ :day    ] = day   ? day.to_i    : nil
    #return { :circa => "day: #{ day }, month: #{ month }, year: #{ year }" }

    #- Some error checking at this point
    if month.to_i > 13
      raise ArgumentError.new( 'Month cannot be greater than 12.' )
    elsif month and day and day.to_i > @days_in_month[ month.to_i ]
      unless month.to_i == 2 and year and Date.parse( '1/1/' + year ).leap? and day.to_i == 29
        raise ArgumentError.new( 'Too many days in this month.' )
      end
    elsif month and month.to_i < 1
      raise ArgumentError.new( 'Month cannot be less than 1.' )
    elsif day and day.to_i < 1
      raise ArgumentError.new( 'Day cannot be less than 1.' )
    end

    month_name = @month_names[ month.to_i ]
    date_parts[ :month_name ] = month_name

    # ----------------------------------------------------------------------

    show_era = ' ' + date_parts[ :era ]
    show_circa = date_parts[ :circa ] == true ? 'About ' : ''

    if year and month and day
      date_parts[ :short  ] = show_circa + month + '/' + day + '/' + year + show_era
      date_parts[ :long   ] = show_circa + month_name + ' ' + day + ', ' + year + show_era
      modified_long = show_circa + month_name + ' ' + day + ', ' + year.rjust( 4, "0" ) + show_era
      date_parts[ :full   ] = show_circa + Date.parse( modified_long ).strftime( '%A,' ) + Date.parse( day + ' ' + month_name + ' ' + year.rjust( 4, "0" ) ).strftime( ' %B %-1d, %Y' ) + show_era
    elsif year and month
      date_parts[ :short  ] = show_circa + month + '/' + year + show_era
      date_parts[ :long   ] = show_circa + month_name + ', ' + year + show_era
      date_parts[ :full   ] = date_parts[ :long ]
    elsif month and day
      month_text = @month_abbreviations.key(month_text) || month_text
      date_parts[ :short  ] = show_circa + day + '-' + month_text
      date_parts[ :long   ] = show_circa + day + ' ' + month_name
      date_parts[ :full   ] = date_parts[ :long ]
    elsif year
      date_parts[ :short  ] = show_circa + year + show_era
      date_parts[ :long   ] = date_parts[ :short  ]
      date_parts[ :full   ] = date_parts[ :long   ]
    end

    return date_parts

  end

  private

  def self.clean_parameter( date )
    date.to_s.strip if date.respond_to? :to_s
  end

  def self.set_up_date_parts( date )
    date_parts = {}
    date_parts[ :original ] = date
    date_parts[ :circa    ] = false
    date_parts[ :year     ] = nil
    date_parts[ :month    ] = nil
    date_parts[ :day      ] = nil
    date_parts[ :era      ] = 'AD'
    date_parts
  end
end
