
require 'base64'
require 'digest'
require 'erb'
require 'ipaddr'
require 'rufus/mnemo'
require 'zip'
require 'securerandom'

module Bento

#----------------------------------------------------------------------------------------------

@@nop = false

def self.nop=(b)
	@@nop = b
end

def self.nop?(*opt)
	nop = opt.include?(:nop)
	no_nop = opt.include?(:nonop)
	raise "conflicting nop and no_nop spec" if nop && no_nop
	!no_nop && (nop || @@nop)
end

#----------------------------------------------------------------------------------------------

def self.realdir(file, rel = "")
	(Pathname.new(file).expand_path.dirname/rel).expand_path
end

#----------------------------------------------------------------------------------------------

def self.obj_module(obj)
	if obj.class?
		mod = obj.module
	elsif obj.is_a?(Module)
		mod = obj
	else
		mod = obj.class.module
	end
	mod
end

def self.module_root(obj)
	Pathname.new(obj_module(obj)::ROOT) rescue nil
end

#----------------------------------------------------------------------------------------------

def self.rand_name
	Rufus::Mnemo.from_i(rand(16**5))
end

def self.short_token
	rand(36**8).to_s(36)
end

def self.secure_token(n = 16)
	SecureRandom.hex(n)
end

#----------------------------------------------------------------------------------------------

def self.uuid
	# UUID.new.generate
	SecureRandom.uuid
end

#----------------------------------------------------------------------------------------------

def self.nowstr
	Time.now.strftime("%y%m%d-%H%M%S%L")
end

#----------------------------------------------------------------------------------------------

def self.keyhash(a, v = 1)
	a.inject({}) { |h,k| h[k.to_s] = v; h } 
end

#----------------------------------------------------------------------------------------------

def self.marshal64(*args)
	Base64.strict_encode64(Marshal.dump(args))
end

def self.demarshal64(d64)
	Marshal.load(Base64.decode64(d64))
end

#----------------------------------------------------------------------------------------------

end # module Bento
