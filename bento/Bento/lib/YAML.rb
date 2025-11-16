
module Bento

#----------------------------------------------------------------------------------------------

class YAML
	include Bento::Class

	members :stream
	attr_reader :stream

	constructors :from_yaml, :from_obj, :from_file

	def from_yaml(yaml)
		@path = nil
		ctor(yaml)
	end

	def from_obj(obj)
		@path = nil
		ctor(obj.to_yaml)
	end

	def from_file(file)
		@path = Pathname.new(file)
		obj = Psych.load_file(@path)
		ctor(obj.to_yaml)
	end

	def ctor(yaml)
		@stream = Psych.parse_stream(yaml)
		fix!
	end

	def fix!
		fix_arrays_to_short_form
	end

	def fix_arrays_to_short_form
		doc = @stream.instance_variable_get("@children")[0].root
		doc.each {|n| n.style = Psych::Nodes::Sequence::FLOW if n.is_a?(Psych::Nodes::Sequence) }
	end

	def to_yaml
		@stream.to_yaml.gsub("---\n", "")
	end

	alias_method :to_s, :to_yaml

	def to_h
		H1.new(::YAML.load(to_yaml))
	end

	def[](x)
		to_h[x]
	end

	def save(path = nil)
		p = path != nil ? path : @path
		error "YAML: file not specified" if !p
		Bento.fwrite(p, to_yaml)
	end

	def append(file)
		open(file, 'a') { |f| f.puts "\n" + to_yaml }
	end
end

#----------------------------------------------------------------------------------------------

end # Bento
