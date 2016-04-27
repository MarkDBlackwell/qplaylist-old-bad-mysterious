=begin
Author: Mark D. Blackwell (google me)
October 9, 2013 - created
October 9, 2013 - updated
Description:

BTW, WideOrbit is a large software system
used in radio station automation.

This program, along with its input and output files,
and a Windows batch file, all reside in the same directory.

The program converts the desired information
(about whatever song is now playing)
from a certain XML file format, produced by WideOrbit,
into an HTML format, suitable for a webpage's iFrame.

The program reads an HTML template file,
substitutes the XML file's information into it,
and thereby produces its output HTML file.

Required gems:
xml-simple
=end

require 'xmlsimple'
# require 'yaml'

module Playlist
  KEYS = %w[ Title Artist ]
  FIELDS = KEYS.map{|e| "[#{e} here]"}

  class Snapshot
    attr_reader :values

    def initialize
      get_values_from_xml unless defined? @@values
      @values = @@values
    end

    protected

    def get_values_from_xml
      relevant_hash = xml_tree['Events'].first['SS32Event'].first
      @@values = KEYS.map{|k| relevant_hash[k].first.strip}
    end

    def xml_tree
# See http://xml-simple.rubyforge.org/
      result = XmlSimple.xml_in 'input.xml', { KeyAttr: 'name' }
#     puts result
#     print result.to_yaml
      result
    end
  end

  class Substitutions
    def initialize(current_values)
      @substitutions = FIELDS.zip current_values
    end

    def run(s)
      @substitutions.each{|input,output| s = s.gsub input, output}
      s
    end
  end
end

def create_output(substitutions)
  File.open 'template.html', 'r' do |f_template|
    lines = f_template.readlines
    File.open 'output.html', 'w' do |f_out|
      lines.each{|e| f_out.print substitutions.run e}
    end
  end
end

song_currently_playing = Playlist::Snapshot.new.values
substitutions = Playlist::Substitutions.new song_currently_playing
create_output substitutions
