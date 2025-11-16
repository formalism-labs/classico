
module Bento

#----------------------------------------------------------------------------------------------

class FileLock
	def initialize(fname)
		@fname = fname
	end

	#------------------------------------------------------------------------------------------

	def try_lock
		lockfile = File.open(@fname, File::RDWR|File::CREAT, 0644)
		locked = lockfile.flock(File::LOCK_EX|File::LOCK_NB) != false
		if !locked
			lockfile.close
			return false
		end
		@lockfile = lockfile
		true
	end

	#------------------------------------------------------------------------------------------

	def lock(seconds = 0, freq_ms = 500)
		return if try_lock
		locked = false
		if seconds > 0
			begin
				sleep(freq_ms)
				locked = try_lock
				seconds -= freq_ms/1000.0
			end while !locked && seconds > 0
		else
			begin
				sleep(500)
			end while !try_lock
		end
	end

	#------------------------------------------------------------------------------------------

	def unlock
		return if @lockfile == nil
		@lockfile.close
		@lockfile = nil
	end
end

#----------------------------------------------------------------------------------------------

end # module Bento
