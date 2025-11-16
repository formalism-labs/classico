
require 'json'

module Bento

#----------------------------------------------------------------------------------------------

class JSON
	include Bento::Class

	constructors :from_json, :from_obj, :from_file

	def from_json(json)
		@file = nil
		ctor(json)
	end

	def from_obj(obj)
		@file = nil
		ctor(obj.to_json)
	end

	def from_file(file)
		@file = file
		ctor(File.read(@file))
	end

	def ctor(json)
		@hash = @array = nil

		j = ::JSON.parse(json)
		if j.hash?
			@hash = H1.new(j)
		elsif j.array?
			@array = j.map {|h| H1.new(h) }
		else
			error "object not compatible with Bento::JSON"
		end
	end

	def to_yaml
		Bento::YAML.from_obj(@hash || @array)
	end

#	alias_method :to_s, :to_json

	def hash?
		@hash != nil
	end

	def to_h(key = nil)
		if @array && !!key
			@array.reduce({}){ |h,x| h[x[key.to_s]] = x; h }
		else
			@hash
		end
	end

	def array?
		@array != nil
	end

	def to_a
		@array
	end

	def to_s
		::JSON.pretty_generate(@hash || @array)
	end
	
	def[](x)
		(@hash || @array)[x]
	end

	def cut(name = nil)
		(@array || [@hash]).cut(name)
	end

	def save(file = nil)
		f = file != nil ? file : @file
		error "file not specified" if !file
		Bento.fwrite(f, to_s)
	end
end

#----------------------------------------------------------------------------------------------

end # Bento
