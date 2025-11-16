
module Bento

#----------------------------------------------------------------------------------------------

# Based on:
# https://github.com/ko1/pretty_backtrace
# https://gist.github.com/mikepfirrmann/3820663

class Backtrace
	def initialize(x, *opt, color: 31)
		x.is_a(Exception)
		@nocolor = opt.include?(:nocolor)
		@color = color
		@context_lines = 2
		@indent = 10

		@text = ""
		describe(x)
	end

	def paint(text, color: nil)
		return text if @nocolor
		color = @color if !color
		"\e[#{color}m#{text}\e[0m"
	end

	def describe(x)
		x.chain.each do |y|
			puts "\n" + "EXCEPTION " + "=" * 70
			puts paint(y.message)
			puts
			y.backtrace.each { |frame| puts desc_frame(frame) }
		end
	end

	def desc_frame(frame)
		if parts = frame.match(/^(?<file>.+):(?<line>\d+):in `(?<code>.*)'$/)
			absolute_path = parts[:file].sub(/^#{Regexp.escape(File.join(Dir.getwd, ''))}/, '')
			lineno = parts[:line].to_i
		else
			text << frame << "\n"
			return
		end

		# fclines = 2
		indent = ' ' * @indent

		start_line = lineno - 1 - 1 * @context_lines
		start_line = 0 if start_line < 0

		text = frame + "\n"

		text << open(absolute_path) {|f| f.readlines[start_line, 1 + 2 * @context_lines]}
			.map
			.with_index{|line, i|
				ln = start_line + i + 1
		  		line = line.chomp
		  		'%s%4d|%s' % [ln == lineno ? indent[0..-3] + "->" : indent, ln, ln == lineno ? paint(line) : line]
			}.join("\n") << "\n" rescue ''

		text << "\n"
	end

	def puts(text = "")
		@text << text + (text[-1] == "\n" ? "" : "\n")
	end

	def to_s
		@text
	end

end

#----------------------------------------------------------------------------------------------

end # module Bento

#----------------------------------------------------------------------------------------------

def bt(x)
	puts Bento::Backtrace.new(x) if x.is_a?(Exception)
end

#----------------------------------------------------------------------------------------------
