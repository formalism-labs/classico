
require 'fileutils'
require 'pathname'
require 'find'
require 'binding_of_caller'

module Bento

#----------------------------------------------------------------------------------------------

$tempfiles = []

at_exit { $tempfiles = [] }

def self.tempfilename(prefix = "temp")
	file = Tempfile.new(prefix)
	$tempfiles << file
	file.close
	file.path
end

#----------------------------------------------------------------------------------------------

def self.tempfile(text)
	path = Bento.tempfilename
	Bento.fwrite(path, text, :nonop)
	path
end

#----------------------------------------------------------------------------------------------

def self.tempcopy(file)
	path = Bento.tempfilename
	FileUtils.cp(file, path)
	path
end

#----------------------------------------------------------------------------------------------

def self.fread(file)
	IO.read(file)
end

#----------------------------------------------------------------------------------------------

def self.fwrite(file, text, *opt)
	nop = Bento.nop?(*opt)
	if !nop
		IO.write(file, text)
	else
		temp = Bento.tempfile(text)
		puts "cp #{temp} #{file}"
	end
end

#----------------------------------------------------------------------------------------------

def self.fwrite_t(file, template, binding_, *opt)
	Bento.fwrite(file, Bento.mold(template, binding_), *opt)
end

#----------------------------------------------------------------------------------------------

def self.fgrep(file, pattern, &block)
	open(file) { |f| f.each_line.grep(pattern) { |x| x.strip } }
end

#----------------------------------------------------------------------------------------------

def Bento.mkdir(dir, *opt)
	nop = Bento.nop?(*opt)
	if !nop
		FileUtils.mkdir_p(dir.to_s)
	else
		puts "mkdir -p #{dir}"
	end	
end

#----------------------------------------------------------------------------------------------

def Bento.cp_r(src, dest, *opt)
	nop = Bento.nop?(*opt)
	if !nop
		FileUtils.cp_r(src, dest)
	else
		puts "cp -r #{src} #{dest}"
	end	
end

#----------------------------------------------------------------------------------------------

def Bento.mv(src, dest, *opt)
	nop = Bento.nop?(*opt)
	if !nop
		FileUtils.mv(src.to_s, dest.to_s)
	else
		puts "mv #{src} #{dest}"
	end	
end

#----------------------------------------------------------------------------------------------

def Bento.rm(files, *opt)
	nop = Bento.nop?(*opt)
	if !nop
		FileUtils.rm(files)
	else
		files = [files] if files.string?
		puts "rm #{files.join(' ')}"
	end	
end

#----------------------------------------------------------------------------------------------

def Bento.rm_r(dir, *opt)
	nop = Bento.nop?(*opt)
	if !nop
		FileUtils.rm_r(dir)
	else
		puts "rm -r #{dir}"
	end	
end

#----------------------------------------------------------------------------------------------

def Bento.find(path = '.')
	paths = path.string? ? [path] : path
	if block_given?
		Find.find(*paths) do |f| 
			yield f.to_s
		end
	else
		found = []
		Find.find(*paths) do |f| 
			found << f.to_s
		end
		found
	end
end

#----------------------------------------------------------------------------------------------

def self.unzip(zipfile, destdir = ".", *opt)
	if Bento.nop?(*opt)
		dd_s = destdir == "." ? "" : "-d #{destdir}"
		puts "unzip #{zipfile} #{dd_s}"
		return
	end
	Zip::File.open(zipfile) do |zip|
		zip.each do |file|
			path = File.join(destdir, file.name)
			Bento.mkdir_p(File.dirname(path))
			zip.extract(file, path) unless File.exist?(path)
		end
	end
end

#----------------------------------------------------------------------------------------------

def self.md5file(file)
	Digest::MD5.file(file).hexdigest
end

#----------------------------------------------------------------------------------------------

def self.md5dir(dir)
	files = Dir["#{dir}/**/*"].reject { |f| File.directory?(f) }
	a = files.map { |file| Digest::MD5.file(file).hexdigest }
	Digest::MD5.hexdigest(a.join)
end

#----------------------------------------------------------------------------------------------

def self.mold(erb_template, binding_ = nil, trim: ">")
	binding_ = binding.of_caller(1) if binding_ == nil
	ERB.new(erb_template, 0, trim).result(binding_)
end

#----------------------------------------------------------------------------------------------

def which(prog)
	exts = OS.windows? && ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
	ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
		exts.each do |ext|
			exe = File.join(path, "#{prog}#{ext}")
			return exe if File.executable?(exe) && !File.directory?(exe)
		end
	end
	nil
end

#----------------------------------------------------------------------------------------------

end # module Bento

#----------------------------------------------------------------------------------------------
 
class Pathname
	def /(x)
		x = x.to_s
		return self if x.empty?
		# prefix of / or \ will cause orignal path to be discarded
		x = x.gsub(/^([\/\\]*)(.*)/, '\2')
		s = to_s
		if Bento::System.ostype == :windows
			if s[-1] == ':'
				Pathname.fix(s + '/' + x)
			elsif s[-2,2] == ":/" || s[-2,2] == ":\\" || s == '/' || s == '\\'
				Pathname.fix(s + x)
			else
				Pathname.fix(s + '/' + x)
			end
			# Pathname.fix(s[-1] == ':' ? s + '/' + x : s + '/' + x)
		else
			Pathname.fix(s + '/' + x)
		end
	end
	
	alias_method :+, :/

	def to_str
		to_s
	end

	def +@
		to_s
		# expand_path
	end

	def ~@
		self
	end

	def to_win
		Pathname.new(to_s.gsub(/\//, '\\'))
	end

	def to_ux
		Pathname.new(to_s.gsub(/\\/, '/'))
	end
	
	def fix
		# if Bento::System.ostype == :windows
		# 	to_win
		# else
		# 	to_ux
		# end
		self
	end

	def self.fix(path)
		Pathname.new(path.to_s).fix
	end

	def newext(ext)
		ext = "." + ext if ! (ext =~ /^\./)
		ext = "" if ext == "."
		name = basename(extname).to_s + ext
		dirname.to_s == "." ? name : dirname/name
	end
	
	def addext(ext)
		ext = "." + ext if ! (ext =~ /^\./)
		ext = "" if ext == "."
		newext(extname + ext)
	end
end

#----------------------------------------------------------------------------------------------

class String
	def ~@
		Pathname(self)
	end
end

#----------------------------------------------------------------------------------------------
 
class Dir
	def Dir.empty?(dir)
		Dir.exist?(dir) && (Dir.chdir(dir){ Dir.glob("{*,.*}") } - [".",".."]).empty?
	end
end

#----------------------------------------------------------------------------------------------
