require "polyglot"
require "treetop"
require "pp"
require "pry"

module WebVtt
  class Cue < Treetop::Runtime::SyntaxNode
    attr_accessor :start, :finish, :settings

    def inspect
      "<Cue start=#{start.inspect} finish=#{finish.inspect} lines=#{lines}>"
    end

    def lines
      l.elements.map(&:to_s)
    end

    def to_s
      settings_string = (@settings || settings.elements.map(&:text_value).join)
      "\n#{@start || start} --> #{@finish || finish}#{settings_string}\n#{l.elements.map(&:to_s).join("\n")}\n"
    end
  end

  class Timestamp < Treetop::Runtime::SyntaxNode
    def inspect
      "#{defined?(hour)}#{minute.value}:#{second.value}"
    end

    def to_s
      hour_string = ""
      if defined?(hour)
        hour_string = ("%02i" % hour.value) + ":"
      end
      "#{hour_string}#{"%02i" % minute.value}:#{("%2.3f" % second.value).rjust(6, "0")}"
    end

    def after(other)
      ([minute.value, second.value] <=> [other.minute.value, other.second.value]) > 0
    end
  end
end

Treetop.load "webvtt"
parser = WebVttParser.new
if parsed = parser.parse(ARGF.read)
  parsed.cues.each_cons(2) do |cue, next_cue|
    if cue.finish.after(next_cue.start)
      $stderr.puts "fixing overlapping: #{cue.inspect} and #{next_cue.inspect}"
      cue.finish = next_cue.start
    end
    if cue.lines.first.start_with?("(")
      cue.settings = " poop"
    end
  end
  puts parsed
else
  puts parser.failure_reason
  puts parser.failure_line
  puts parser.failure_column
end
