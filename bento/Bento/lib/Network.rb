
module Bento

#----------------------------------------------------------------------------------------------

def self.ip_cidr(ip, mask)
	ip + "/" + IPAddr.new(mask).to_i.to_s(2).count("1").to_s
end

def self.ip_cidr_split(ip_cidr)
	ip_cidr =~ /([^\/]+)(\/.*)/
	[$1, $2]
end

def self.netmask_from_cidr(cidr)
	IPAddr.new('255.255.255.255').mask(cidr[1..-1]).to_s
end

def self.netmask_to_cidr(mask)
	"/" + IPAddr.new(mask).to_i.to_s(2).count("1").to_s
end

#----------------------------------------------------------------------------------------------

class IPv4Address
	def is(ip)
	end

	def cidr_split
	end

	def ip
	end

	def mask
	end

	def cidr
	end

	def to_s
	end
end

#----------------------------------------------------------------------------------------------

class IPv4WithMask
	def is(ip_cidr)
	end

	def ip
	end

	def mask
	end

	def cidr
	end

	def to_s
	end
end

#----------------------------------------------------------------------------------------------

class MACAddress
	def initialize(mac)
		@mac = MACAddress.fix(mac)
	end

	def self.equal?(m1, m2)
		MACAddress.fix(m1) == MACAddress.fix(m2)
	end

	def ==(mac)
		@mac == MACAddress.fix(mac)
	end

	def self.fix(mac)
		m = mac.to_s.gsub(/[^\w]/, "").downcase
		raise "invalid mac address: '#{mac}'" if m.length != 12 || (m =~ /[^0-9a-f]/) != nil
		m
	end

	def style(styl)
		case styl
		when :linux
			@mac.scan(/.{1,2}/).join(':')
		when :windows
			@mac.scan(/.{1,2}/).join('-')
		when :cisco
			@mac.scan(/.{1,4}/).join('.')
		else
			@mac.scan(/.{1,2}/).join(':')
		end
	end

	def to_s
		style(:linux)
	end
end

#----------------------------------------------------------------------------------------------

end # module Bento
