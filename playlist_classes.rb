require 'cgi'
require 'mustache'
require 'xmlsimple'
# require 'yaml'

module Playlist
  NON_XML_KEYS = %w[ current_time ]
      XML_KEYS = %w[ artist title ]
  KEYS = NON_XML_KEYS + XML_KEYS

  class Snapshot
    attr_reader :values

    def initialize
      get_non_xml_values
      get_xml_values unless defined? @@xml_values
      @values = @@non_xml_values + @@xml_values
    end

    protected

    def get_non_xml_values
      @@non_xml_values = NON_XML_KEYS.map do |k|
        case k
        when 'current_time'
          Time.now.localtime.round.strftime '%-l:%M %p'
        else
          "(Error: key '#{k}' unknown)"
        end
      end
    end

    def get_xml_values
      relevant_hash = xml_tree['Events'].first['SS32Event'].first
      @@xml_values = XML_KEYS.map(&:capitalize).map{|k| relevant_hash[k].first.strip}
    end

    def xml_tree
# See http://xml-simple.rubyforge.org/
      result = XmlSimple.xml_in 'now_playing.xml', { KeyAttr: 'name' }
#     puts result
#     print result.to_yaml
      result
    end
  end #class

  class Substitutions
    def initialize(fields, current_values)
      @substitutions = fields.zip current_values
    end

    def run(s)
      @substitutions.each do |input,output|
#print '[input,output]='; p [input,output]
        safe_output = CGI.escape_html output
        s = s.gsub input, safe_output
      end
      s
    end
  end #class

  class NowPlayingSubstitutions < Substitutions
    def initialize(current_values)
      fields = KEYS.map{|e| "{{#{e}}}"}
      super fields, current_values
    end
  end #class

  class LatestFiveSubstitutions < Substitutions
    def initialize(current_values)
      key_types = %w[ start_time artist title ]
      count = 5
      fields = (1..count).map(&:to_s).product(key_types).map{|digit,key| "{{#{key}#{digit}}}"}
#print 'fields='; p fields
      super fields, current_values
    end
  end #class

  class Songs < Mustache
    def initialize(a)
      @array_of_hashed_songs = a
    end

    def songs
      @array_of_hashed_songs
    end
  end #class

  class Run
    def build_recent(f_recent_songs, currently_playing)
      input_file  = 'recent_songs.moustache'
      output_file = 'recent_songs.html'
    end

    def compare_recent(currently_playing)
      remembered, artist_title, same = nil, nil, nil # Define in scope.
      File.open 'current-song.txt', 'r+' do |f_current_song|
        remembered = f_current_song.readlines.map &:chomp
        artist_title = currently_playing.drop 1
        same = remembered == artist_title
        unless same
          f_current_song.rewind
          f_current_song.truncate 0
          artist_title.each{|e| f_current_song.print "#{e}\n"}
        end
      end
      same ? 'same' : nil
    end

    def create_output(substitutions, input_template_file, output_file)
      File.open input_template_file, 'r' do |f_template|
        lines = f_template.readlines
        File.open output_file, 'w' do |f_out|
          lines.each{|e| f_out.print substitutions.run e}
        end
      end
    end

    def create_output_recent_songs(dates, times, artists, titles)
      songs = dates.zip(times,artists,titles).map do |date,time,artist,title|
        year, month, day = date.split ' '
        clock, meridian = time.split ' '
        hour, minute = clock.split ':'
        {
          artist:   artist,
          title:    title,
          time:     time,
          year:     year,
          month:    month,
          day:      day,
          hour:     hour,
          minute:   minute,
          meridian: meridian, # 'AM' or 'PM'.
        }
      end
# Songs.template_extension = 'moustache' # Allow for my error in the naming.
      Songs.template_file = './recent_songs.moustache'
      File.open 'recent_songs.html', 'w' do |f_output|
        f_output.print Songs.new(songs.reverse).render
      end
    end

    def latest_five_songs_get(times, artists, titles)
      songs_to_keep = 5
      song_count = titles.length
      songs_to_drop = song_count <= songs_to_keep ? 0 : song_count - songs_to_keep
      [
        (times.  drop songs_to_drop),
        (artists.drop songs_to_drop),
        (titles. drop songs_to_drop),
      ].transpose.reverse.
          fill(['','',''], song_count...songs_to_keep).flatten
    end

    def recent_songs_get(currently_playing)
# 'r+' is "Read-write, starts at beginning of file", per:
# http://www.ruby-doc.org/core-2.0.0/IO.html#method-c-new
      n = Time.now.localtime.round
      year_month_day = Time.new(n.year, n.month, n.day).strftime '%4Y %2m %2d'
      dates, times, artists, titles = nil, nil, nil, nil # Define in scope.
      File.open 'recent-songs.txt', 'r+' do |f_recent_songs|
        dates, times, artists, titles = recent_songs_read f_recent_songs
# Push current song:
        dates.push          year_month_day
        f_recent_songs.puts year_month_day
        times.  push currently_playing.at 0
        artists.push currently_playing.at 1
        titles. push currently_playing.at 2
        currently_playing.each{|e| f_recent_songs.print "#{e}\n"}
      end
      [dates, times, artists, titles]
    end

    def recent_songs_read(f_recent_songs)
      dates, times, artists, titles = [], [], [], []
      lines_per_song = 4
      a = f_recent_songs.readlines.map &:chomp
      song_count = a.length.div lines_per_song
      (0...song_count).each do |i|
        dates.  push a.at i * lines_per_song + 0
        times.  push a.at i * lines_per_song + 1
        artists.push a.at i * lines_per_song + 2
        titles. push a.at i * lines_per_song + 3
      end
      [dates, times, artists, titles]
    end

    def recent_songs_reduce(year_month_day, old_dates, old_times, old_artists, old_titles)
      comparison_date = year_month_day - 60 * 60 * 24 * 2 # Day before yesterday.
      big_array = []
      (0...old_dates.length).each do |i|
        year, month, day = old_dates.at(i).split(' ').map &:to_i
        song_time = Time.new year, month, day
        unless song_time < comparison_date
          big_array.push old_dates.  at i
          big_array.push old_times.  at i
          big_array.push old_artists.at i
          big_array.push old_titles. at i
        end
      end
      File.open 'recent-songs.txt', 'w' do |f_recent_songs|
        big_array.each{|e| f_recent_songs.print "#{e}\n"}
      end
    end

    def run
      now_playing = Playlist::Snapshot.new.values
      now_playing_substitutions = Playlist::NowPlayingSubstitutions.new now_playing
      create_output now_playing_substitutions, 'now_playing.moustache', 'now_playing.html'

      unless 'same' == (compare_recent now_playing)
        dates, times, artists, titles = recent_songs_get now_playing
        latest_five = latest_five_songs_get times, artists, titles
#print 'latest_five='; p latest_five
        latest_five_substitutions = Playlist::LatestFiveSubstitutions.new latest_five
#print 'latest_five_substitutions='; p latest_five_substitutions
        create_output latest_five_substitutions, 'latest_five.moustache', 'latest_five.html'
        create_output_recent_songs dates, times, artists, titles
        n = Time.now.localtime.round
        year_month_day_hour_string = Time.new(n.year, n.month, n.day, n.hour).strftime '%4Y %2m %2d %2H'
        year_month_day             = Time.new n.year, n.month, n.day
        File.open 'current-hour.txt', 'r+' do |f_current_hour|
          unless f_current_hour.readlines.push('').first.chomp == year_month_day_hour_string
            recent_songs_reduce year_month_day, dates, times, artists, titles
            f_current_hour.rewind
            f_current_hour.truncate 0
            f_current_hour.print "#{year_month_day_hour_string}\n"
          end
        end
      end
    end
  end #class
end #module
