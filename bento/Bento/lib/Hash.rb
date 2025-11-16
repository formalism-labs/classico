
module Bento

#----------------------------------------------------------------------------------------------

class H1 < Hash

	Self = self

	def initialize(h = nil)
		replace(h) if h != nil
	end
	
	def [](k)
		v = fetch(k, nil)
		return v if !v.is_a?(Hash)
		store(k, v = Self.new(v))
		v
	end

	def []=(k, w)
		if w.is_a?(Hash)
			store(k, Self.new(w))	
		else
			store(k, w)
		end
	end

	def <<(h)
		merge!(h)
	end
	
	def merge(h)
		g = deep_clone
		g.merge!(h)
	end
	
	def merge!(h)
		h.each do |k, v|
			v0 = fetch(k, nil)
			if v0 == nil
				store(k, v)
			else
				store(k, v0.merge!(v))
			end
		end
		self
	end
	
	def method_missing(m, *args)
		if m.to_s[-1] == '='
			m = m[0..-2]
			k = m.to_sym
			v = args.first
			v = Self.new(v) if v.is_a?(Hash)
			if has_key?(k)
				store(k, v)
			else
				store(m, v)
			end
		else
			v = fetch(m, nil)
			v = fetch(m.to_s.gsub(/_/, "-"), nil) if v == nil
			store(m, v = Self.new(v)) if v.hash?
			v
		end
	end

	def to_h
		reduce({}) { |h, (k,v)| h[k] = v.is_a?(H1) ? v.to_h : v; h }
	end
end

#----------------------------------------------------------------------------------------------

# RegHash: Hash of hashes
# Each key can have a :value subkey, holding a non-hash value

class RegHash < Hash

	Self = self

	def initialize(h = nil)
		replace(h) if h != nil
	end
	
	def [](k)
		v = fetch(k, nil)
		return v if !v.hash?
		Self.new(v)
	end

	def value
		fetch(:value, nil)
	end
	
	def _store(k, v)
		if v.hash?
			merge!({k => v})
		else
			merge!({k => {:value => v}})
		end
	end

	def []=(k, v)
		_store(k, v)
	end

	def <<(hoh)
		merge!(hoh)
	end
	
	def merge(hoh)
		h = deep_clone
		h.merge!(hoh)
	end
	
	def merge!(hoh)
		Self.merge_hoh(self, hoh)
	end
	
	def self.merge_hoh(x, y)
		return Self.try_convert({ :value => x }).merge!(y) if !x.hash?
		y.each do |k, v|
			xv = x.fetch(k, nil)
			if xv == nil
				x.store(k, v)
			else
				x.store(k, Self.merge_hoh(xv, v))
			end
		end
		x
	end

	def method_missing(m, *args)
		if m.to_s[-1] == '='
			m = m[0..-2]
			k = m.to_sym
			if has_key?(k)
				store(k, args.first)
			else
				store(m, args.first)
			end
		else
			v = fetch(m.to_s, nil)
			if v == nil
				self[m.to_s.gsub(/_/, "-")]
			else
				return v if !v.hash?
				Self.new(v)
			end
		end
	end
end

#----------------------------------------------------------------------------------------------

class AHash < Hash
	def initialize(*opt)
		super(*opt) {|h,k| h[k]=[]}
	end
end

#----------------------------------------------------------------------------------------------

end # module Bento
