
require 'inifile'
require 'linguistics'

Linguistics.use :en, monkeypatch: true rescue nil

module Bento

#----------------------------------------------------------------------------------------------

module Text

#----------------------------------------------------------------------------------------------

# compact whitespace (newlines, tab, spaces) into single occurence of each ws char
def self.compact(s)
	a1 = s.lines.keep_if {|x| x != "\n"}
	s2 = a1.map { |x| x.gsub(/[ \t]+/, " ") }
	s2.join
end

#----------------------------------------------------------------------------------------------

def self.indent(s)
	lines = s.lines
	fragments = lines.map {|x| x.split(" ")}
	n = fragments.map {|f| f.length}.max
	lengths = fragments.map {|line| line.map {|f| f.length}}
	columns = []
	for i in 0..n-1 do
		columns << lengths.map {|x| i < x.size ? x[i] : 0}.max
	end
	s = ""
	fragments.each do |line|
		for i in 0..line.length-1 do
			s += (i == 0 ? "" : " ") + sprintf("%-#{columns[i]}s", line[i])
		end
		s = s.strip + "\n"
	end
	s
end

#----------------------------------------------------------------------------------------------

end # Text

#----------------------------------------------------------------------------------------------

class Sed
	attr_reader :file

	# opt: :copy
	def initialize(file, *opt)
		copy = opt.include? :copy
		@file = copy ? Bento.tempcopy(file) : file
	end

	# opt: :nocase
	def replace_one(source, dest, *opt)
		sed("s/#{source}/#{dest}/")
	end

	# opt: :nocase
	def replace_all(source, dest, *opt)
		sed("s/#{source}/#{dest}/g")
	end

	alias_method :replace, :replace_all

	# opt: :before, :after, :top, :bottom
	def insert_line(pattern, text, *opt)
		before = opt.include? :before
		# after = opt.include? :after
		top = opt.include? :top
		bottom = opt.include? :bottom

		if top
			sed("1s/^/#{text}/")
		elsif bottom
			sed("\$a#{text}")
		else
			op = before ? "i" : "a"
			sed("/#{pattern}/#{op}#{text}")
		end

	end

	def replace_between(this, that, find, with)
		sed("/#{this}/,/#{that}/ s/#{find}/#{with}/")
	end

	def delete_lines(pattern)
		sed("/#{pattern}/d")
	end

	def if(pattern)
		if Bento.fgrep(@file, pattern).count > 0
			if block_given?
				yield(self)
			else
				self
			end
		else
			Sed_nop.new if !block_given?
		end
	end

	def unless(pattern)
		if Bento.fgrep(@file, pattern).count == 0
			if block_given?
				yield(self)
			else
				self
			end
		else
			Sed_nop.new if !block_given?
		end
	end

	def sed(script)
		script.gsub!(/\n/, "\\n")
		script.gsub!(/\t/, "\\t")

		# this is redundant, but the idea is good :)
		if Bento.nop? && script =~ /\n/
			temp = Bento.tempfile(script)
			systemx("sed -i -r -f #{temp} #{@file}")
		else	
			systemx("sed -i -r -e '#{script}' #{@file}")
		end
		self
	end

	class << self
		Sed_nop = ::Class.new(Object) do
			Sed.instance_methods(false).each do |m|
				define_method(m) { |*args| self }
			end
		end
		Sed.const_set("Sed_nop", Sed_nop)
	end
end

#----------------------------------------------------------------------------------------------

def self.sed(*args)
	Sed.new(*args)
end

#----------------------------------------------------------------------------------------------

class IniFile

	attr_reader :ini, :file

	class Section
		attr_reader :parent, :name
	
		def initialize(parent, name)
			@parent = parent
			@name = name
		end
	
		def [](item)
			section[item]
		end
		
		def []=(item, value)
			set(item, value)
		end

		def set(item, value, comment: "")
			value = value.to_s
			comment = comment + "\n" if !comment.empty?
			if section[item]
				Bento.sed(parent.file).replace_between("^\\[#{name}\\]", 
					'^\[', "^(\\s*#{item}\\s*=\\s*)(.*)", "#{comment}\\1#{value}")
			else
				Bento.sed(parent.file).insert_line("\\[#{name}\\]", "#{comment}#{item}=#{value}")
			end
			parent.reload
			self
		end

		def section
			parent.ini[name]
		end
	end

	def initialize(file)
		@file = file
		reload
	end

	def [](name)
		return nil if !ini.has_section?(name)
		Section.new(self, name)
	end
	
	def append(text)
		Bento.sed(file).insert_line(nil, text, :bottom)
	end

	def reload
		@ini = ::IniFile::load(file)
	end
end

#----------------------------------------------------------------------------------------------

end # Bento

#----------------------------------------------------------------------------------------------

class String
	def indent(count, char = ' ')
		gsub(/([^\n]*)(\n|$)/) do |match|
			last_iteration = $1 == "" && $2 == ""
			line = ""
			line << (char * count) unless last_iteration
			line << $1
			line << $2
			line
		end
	end

	def unindent
		gsub(/^#{scan(/^\s*/).min_by{|l|l.length}}/, "")
	end

	def !@
		empty?
	end

	def to_bool
		case downcase
		when 'true', 'yes'; true
		when 'false', 'no'; false
		else; nil
		end
	end
end

#----------------------------------------------------------------------------------------------
