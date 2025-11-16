
# require 'Bento'

#----------------------------------------------------------------------------------------------

module Bento

module NEXP

#----------------------------------------------------------------------------------------------

class Pos
	attr_reader :line, :pad

	def initialize(line = 0, pad = "")
		@line, @pad = line, pad
	end
end

#----------------------------------------------------------------------------------------------

class Node
	include Bento::Class

	attr_reader :start, :end, :free

	def initialize(pos)
		if pos.is_a? Array
			@start, @end = *pos
		else
			@start = pos
		end
	end

	def atom? ; false ; end
	def list? ; false ; end
	def nil? ; false ; end

	def +@
		list?
	end
	
	def ~
		skel
	end

	def to_str
		to_s
	end
	

	def line
		start.line
	end

	def pos
		if !@end
			@start
		else
			[@start, @end]
		end
	end
end

#----------------------------------------------------------------------------------------------

class Nil < Node
	include Enumerable

	def initialize
		super(0)
	end

	def list?
		true
	end

	def nil?
		true
	end

	def to_s
		""
	end

	def skel
		[]
	end

	def car
		self
	end

	def cdr
		Nodes.new(0, [])
	end

	def each
	end
end

#----------------------------------------------------------------------------------------------

class Atom < Node
	attr_reader :text

	def initialize(text, pos = Pos.new)
		super(pos)
		@text = text
	end

	def list?
		false
	end
	
	def atom?
		true
	end

	def to_s
		@text
	end

	def to_i
		@text.to_i
	end

	def to_f
		@text.to_f
	end

	def skel
		to_s
	end
	
	def value=(x)
		@text = x
	end

	def car
		self
	end

	def cdr
		Nodes.new([], 0)
	end
end

#----------------------------------------------------------------------------------------------

class Nodes < Node
	include Enumerable

	def initialize(list = [], pos = Pos.new)
		super(pos)
		@list = list
	end

	def get(x)
		@list.find(x)
	end
	
	def list?
		true
	end
	
	def atom?
		false
	end
	
	def <<(x)
		if x.is_a?(Node)
			node = x
		elsif x.is_a?(Array)
			node = Nodes.new
			x.each { |y| node << y }
		else
			node = Atom.new(x.to_s)
		end
		@list << node
	end
	
	def empty?
		@list.empty?
	end

	def to_s
		@list.empty? ? "" : @list[0].to_s
	end

	def skel
		@list.map { |node| node.skel }
	end

	def find(x)
		return @list[x] if x.is_a? Fixnum

		x = x.to_s
		i = @list.find_index {|y| y.to_s == x }
		return @list[i] if i != nil

		# let's try searching for :x
		x = ":#{x}"
		i = @list.find_index {|y| y.to_s == x }
		return nil if i == nil

		@list[i]
	end

	def node(x, *opt)
		nodes_opt = opt.include?(:nodes)
		return @list[x] if x.is_a? Fixnum

		x = x.to_s
		i = @list.find_index {|y| y.to_s == x }
		if i == nil
			# let's try searching for :x
			x = ":#{x}"
			i = @list.find_index {|y| y.to_s == x }
			return Nil.new if i == nil

			if @list[i].atom?
				# (:a b c)[:a] yields b
				return @list[i+1]
			else
				# ((:a b c) x y)[:a] yields (b c)
				# fall through
			end
		end

		if @list[i].atom?
			# (a b c)[:a] yields (b c)
			cdr = @list.drop(i + 1)
		else
			# ((a 1 2) b c)[:a] yields (1 2)
			n = @list[i]
			cdr = n.list.drop(1)
		end
		return Nodes.new([], n.pos) if cdr.size == 0
		return cdr[0] if cdr.size == 1 && !nodes_opt
		Nodes.new(cdr, cdr[0].pos)
	end

	def nodes(x, *opt)
		node(x, :nodes)
	end

	def [](x)
		node(x)
	end
	
	def []=(i, x)
		node(i).value = x
	end

	def list
		@list
	end

	def size
		list.size
	end

	def cxr(x, y = self)
		return y if x.empty?
		case x[-1]
			when 'a'
				return nil if y.size == 0
				y = y[0]
			when 'd'
				return nil if y.size == 1
				y = Nodes.new(y.list.drop(1), y[1].pos)
			else
				raise "invalid cxr specification"
		end
		cxr(x[0...-1], y)
	end
	
	def car;    cxr :a;    end
	def cdr;    cxr :d;    end
	def caar;   cxr :aa;   end
	def cadr;   cxr :ad;   end
	def cdar;   cxr :da;   end
	def cddr;   cxr :dd;   end
	def caaar;  cxr :aaa;  end
	def caadr;  cxr :aad;  end
	def cadar;  cxr :ada;  end
	def caddr;  cxr :add;  end
	def cdaar;  cxr :daa;  end
	def cdadr;  cxr :dad;  end
	def cddar;  cxr :dda;  end
	def cdddr;  cxr :ddd;  end
	def caaaar; cxr :aaaa; end
	def caaadr; cxr :aaad; end
	def caadar; cxr :aada; end
	def caaddr; cxr :aadd; end
	def cadaar; cxr :adaa; end
	def cadadr; cxr :adad; end
	def caddar; cxr :adda; end
	def cadddr; cxr :addd; end
	def cdaaar; cxr :daaa; end
	def cdaadr; cxr :daad; end
	def cdadar; cxr :dada; end
	def cdaddr; cxr :dadd; end
	def cddaar; cxr :ddaa; end
	def cddadr; cxr :ddad; end
	def cdddar; cxr :ddda; end
	def cddddr; cxr :dddd; end

	def each(what = nil)
		if what == nil
			@list.each { |x| yield x }
		else
			what = what.to_s
			@list.each { |x| yield x if x.to_s == what }
		end
	end

	# filter nodes by 1st element
	# ((node 1) (node 2) (goat))/:node yields ((node 1) (node 2))
	def cut(what)
		y = []
		each(what) { |x| y << x }
		return nil if y == []
		Nodes.new(y, y[0].pos)
	end
	
	def /(what)
		cut(what)
	end
	
	def sel0(what)
		node(what)
	end

	# selects nodes by 2nd element
	# ((node a foo) (node b bar))%:a yields (foo)
	# ((node a foo) (node a bar))%:a yields [(foo) (bar)]
	def sel1(what)
		what = what.to_s
		y = select {|x| ~x.cadr == what}
		return nil if y == []
		y = y.map {|x| x.drop(2)}
		return nil if y == []
		y = y[0]
#		if y[0].count == 1
			y = y[0]
			Nodes.new([y], y.pos)
#		else
#			y.map{|x| Nodes.new(x, x[0].pos)}
#		end
	end
	
	def %(what)
		sel1(what)
	end

	# ((a 1) (b 2) (c 3)) yields [a b c]
	def rank0
		map { |x| ~x.car }
	end

	# ((node a) (node b) (node c)) yields [a b c]
	def rank1
		map { |x| ~x.cadr }
	end

	class Print
		def initialize(nodes, *opt)
			@line = nodes.start.line
			free = nodes.free || opt.include?(:free)
			@indent = nodes.start.pad
			@newline = true

			@s = ''
			@s += pad(nodes.start) + '(' if !free
			@s += print(nodes)
			@s += (nodes.end ? pad(nodes.end) : '') + ')' if !free
		end

		def to_s
			@s
		end

		private

		def pad(pos)
			return pos.pad if !@newline
			s = pos.pad
			s.index(@indent) == 0 ? s[@indent.length..-1] : s
		end

		def print(nodes)
			s = ''
			nodes.list.each do |node|
				while @line < node.start.line
					@line += 1
					s += "\n"
					@newline = true
				end
				if node.atom?
					s += pad(node.start) + node.text
				else
					s += pad(node.start) + '(' + print(node)
					while @line < node.end.line
						@line += 1
						s += "\n"
						@newline = true
					end
					s += pad(node.end) + ')'
				end
				@newline = false
			end
			s
		end
	end

	# optinos: :free - do not wrap in ()
	def text(*opt)
		Print.new(self, *opt).to_s
	end

end

#----------------------------------------------------------------------------------------------

class Stream
	attr_reader :line, :col
	
	def initialize(stream)
		@stream = stream
		@line = 1
		@col = 0
		@newline = false
		@linebuf = ''
	end

	def read
		return "" if @stream == nil
		c = @stream.getc
		return "" if c == nil
		@col += 1
		@linebuf += c
		if @newline
			@col = 0
			@line += 1
			while c == "#"
				@stream.gets
				c = @stream.getc
			end
		end
		@newline = c == "\n"
		if @newline
			@linebuf1 = @linebuf
			@linebuf = ''
		end
		return c
	end

	def atEnd?
		return true if @stream == nil
		if @stream.eof?
			@stream.close
			@stream = nil
			true
		else
			false
		end
	end
	
	def >>(x)
		x = read
	end
end

#----------------------------------------------------------------------------------------------

class Nexp < Nodes
	include Bento::Class

	constructors :is, :from_s, :from_file
	members :stream, :single, :line, :list_tops, :list, :start, :end, :free

	def ctor(stream, *opt, filename: '')
		@stream = Stream.new(stream)
		@single = opt.include? :single

		@line = 0
		@list_tops = @single ? [] : [Pos.new(1, "")]
		nodes = read
		nodes = nodes[0] if @single

		@list = nodes.list
		@start, @end = nodes.start, nodes.end
		@free = !@single
	end

	private :ctor

	def is(fname, *opt)
		from_file(fname, *opt)
	end

	def from_s(text, *opt)
		ctor(StringIO.new(text), *opt)
	end
	
	def from_file(fname, *opt)
		ctor(File.open(fname, "r"), *opt, filename: fname)
	end

	def read(root = true)
		nodes_list = []
		token = ""
		pad = ""
		state = :sep
		loop do
			c = @stream.read
			@line = @stream.line
			read_ch = false
			while !read_ch do
				case state
					when :sep
						if @stream.atEnd?
							state = :end
						else
							case c
								when ")"
									state = :end
								when "("
									state = :list
								when "\n"
									read_ch = true
									state = :newline
								else
									if Nexp.atom?(c)
										# token = c
										state = :atom
									else
										pad += c
										read_ch = true
									end
							end
						end

					when :newline
						if c == "#"
							read_ch = true
							state = :comment
						else
							state = :sep
						end

					when :comment
						read_ch = true
						state = :newline if c == "\n"

					when :atom
						if @stream.atEnd? || Nexp.sep?(c)
							nodes_list << Atom.new(token, Pos.new(@line, pad))
							token = ""
							pad = ""
							state = :sep
						else
							c = @stream.read if Nexp.esc?(c)
							token << c
							read_ch = true
						end

					when :list
						@list_tops.push(Pos.new(@line, pad))
						pad = ""
						nodes = read(false)
						if !nodes.empty?
							nodes_list << nodes
							read_ch = true
							state = :sep
						else
							state = :end
						end

					when :end
						raise "expected ) at end of file" if !root && c != ")"
						return Nodes.new(nodes_list, [@list_tops.pop, Pos.new(@line, pad)])

					else
						raise "invalid state"
				end
			end
		end
	end

	def self.atom?(c)
		c > ' '
	end

	def self.esc?(c)
		c == "\\"
	end

	def self.sep?(c)
		c <= " " || c == "(" || c == ")"
	end

end # class Nexp

#----------------------------------------------------------------------------------------------

end # module NEXP

Nexp = NEXP::Nexp # class

end # module Bento

#----------------------------------------------------------------------------------------------

NExp = Bento::NEXP::Nexp # class

def Nexp(*args)
	Bento::NEXP.Nexp(*args)
end
