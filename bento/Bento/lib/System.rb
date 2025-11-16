
require 'os'
require 'etc'
require 'rbconfig'

module Bento

#----------------------------------------------------------------------------------------------

module System

#----------------------------------------------------------------------------------------------

def System.user
	Etc.getlogin.downcase
end

#----------------------------------------------------------------------------------------------

def System.ad_domain
	if OS.windows?
		ENV['USERDOMAIN']
	else
		nil # maybe use "net" commnad
	end
end

#----------------------------------------------------------------------------------------------

def System.ostype
	return :linux if OS.linux?
	return :windows if OS.windows? # also Gem.win_platform?
	x = RbConfig::CONFIG['host_os']
	return :solaris if false
	return :macosx if x =~ /darwin/
	return :freebsd if x =~ /freebsd/
	error 'Cannot determine OS type'
end

#----------------------------------------------------------------------------------------------

def System.os
	case System.ostype
		when :linux
			id = Bento.fread('/etc/os-release').lines.grep(/^ID=(\w+)/) { $1.chomp }
			case id[0]
				when "ubuntu"; :ubuntu_linux
				when "fedora"; :fedora_linux
				when "centos"; :centos_linux
				when "coreos"; :coreos_linux
				when "debian"; :debian_linux
				else; :linux
			end
		when :windows
		when :solaris
		when :freebsd
	end
end

#----------------------------------------------------------------------------------------------

def System.arch
	case RbConfig::CONFIG['host_cpu']
		when 'x86_64'; :x64
		when 'i486'; :x32
		when 'arm'; :arm
		when 'amd64'; :x64
		else; nil
	end
end

#----------------------------------------------------------------------------------------------

def System.bintype
	"#{System.ostype}-#{System.arch}"
end

#----------------------------------------------------------------------------------------------

def System.osver
	case System.ostype
		when :linux
			verid = Bento.fread('/etc/os-release').lines.grep(/^VERSION_ID="?([^"]+)"?/) { $1.chomp }
			ver = verid[0]
		when :windows
		when :solaris
	end
	error "cannot detect OS version" if ver.empty?
	ver
end

#----------------------------------------------------------------------------------------------

def System.cpu_count
	case System.ostype
		when :linux
			`cat /proc/cpuinfo | grep processor | wc -l`.to_i
		when :windows
			ENV["NUMBER_OF_PROCESSORS"].to_i
		when :solaris
			`psrinfo -v | grep ^Status | tail -1 | awk '{x = $5 + 1; print x;}'`.to_i
	end
end

#----------------------------------------------------------------------------------------------

def System.hostname(*opt)
	h = Socket.gethostname.downcase
	if opt.empty? || opt.include?(:long)
		h
	elsif opt.include? :short
		h =~ /([^.]*)\.?(.*)/
		$1
	elsif opt.include? :domain
		h =~ /([^.]*)\.?(.*)/
		$2
	else
		nil
	end
end

def System.short_hostname
	Socket.gethostname.downcase =~ /([^.]*)\.?(.*)/
	$1
end

def System.full_hostname
	Socket.gethostname.downcase
end

def System.domainname
	Socket.gethostname.downcase =~ /([^.]*)\.?(.*)/
	$2
end

#----------------------------------------------------------------------------------------------

def System.command(cmd, *opt, at: nil)
	return Command.new(cmd, *opt, at: at)
end

#----------------------------------------------------------------------------------------------

def System.commandx(cmd, *opt, at: nil)
	c = Command.new(cmd, *opt, at: at)
	error "in System.command(#{cmd})" if c.status != 0
	return c
end

#----------------------------------------------------------------------------------------------

end # module System

#----------------------------------------------------------------------------------------------

end # module Bento
