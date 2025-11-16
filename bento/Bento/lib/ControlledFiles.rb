
module Bento

#----------------------------------------------------------------------------------------------

class ControlledFiles
	include Bento::Class
	
	attr_reader :unmerged_elems

	constructors :is, :create
	
	#------------------------------------------------------------------------------------------

	def is(name, path, app: nil)
		@name = name.to_s
		if app
			@gpath = app.root/path/"#{name}.git"
			@lpath = app.lu_root/path/name
		else
			@gpath = +~path/"#{name}.git"
			@lpath = +~path/name
		end
		
		@unmerged_elems = []

		error "merge pedning on #{@lpath}" if sync! == :merge_in_progress
	end
	
	#------------------------------------------------------------------------------------------

	def create(name, path, source: nil, app: nil)
		error "source not specified" if !source

		@name = name.to_s
		if app
			@gpath = app.root/path/"#{name}.git"
			@lpath = app.lu_root/path/name
		else
			@gpath = +~path/"#{name}.git"
			@lpath = +~path/name
		end
		git_lpath = +(@lpath/"..")
		source = +~source
		
		error "directoy #{@gpath} exists" if @gpath.exist?
		error "directoy #{lgpath} exists" if @lpath.exist?
		
		Bento.mkdir(@gpath)
		Dir.chdir(@gpath) do
			systemx("git init --bare")
		end

		Bento.mkdir(git_lpath)
		Dir.chdir(git_lpath) do
			systemx("git clone file:///#{@gpath.to_ux}")
			@lpath /= @name
			at_git do
				Bento.cp_r(source/".", ".")
				systemx("git add -A")
				systemx("git commit -a -m''")
				systemx("git push origin --all")
			end
		end

		@unmerged_elems = []
	end

	#------------------------------------------------------------------------------------------

	def[](path)
		@lpath/path
	end
	
	def good?
		unmerged_elems == []
	end

	def unmerged_files
		unmerged_elems.map { |p| @lpath/p }
	end
	
	def unmerged_elements
		unmerged_elems
	end

	#------------------------------------------------------------------------------------------

	def sync!
		case stat = status
		when :ready, :merge_in_progress
			return stat
		end
		commit!
		return :ready if up_to_date?
		try_merge!
	end
	
	#------------------------------------------------------------------------------------------

	# returns :ready, :need_sync, :merge_in_progress
	def status
		at_git do
			stat = systemx("git status --porcelain")
			return :ready if stat.out.size == 0

			file_states = stat.out.map {|x| x.split(/\s+/)}
			unmerged = file_states.select { |pair| pair.first =~ /U/ }
			return :need_sync if unmerged.empty?
			
			@unmerged_elems = unmerged.map { |pair| pair[1] } # unmerged.map(&:cadr)
			:merge_in_progress
		end
	end

	#------------------------------------------------------------------------------------------

	def commit!
		at_git do
			systemx("git add -A")
			commit = systema("git commit -a -m''")
			if commit.status == 1
				commit.error! if commit.out[-1] != "nothing to commit, working directory clean"
			elsif commit.status != 0
				commit.error!
			end
		end
	end

	#------------------------------------------------------------------------------------------

	def try_merge!
		at_git do
			pull = systema("git pull --commit")
			return :merge_in_progress if pull.failed?
			systemx("git push origin --all")
		end
		:ready
	end

	#------------------------------------------------------------------------------------------

	def at_git
		Dir.chdir(@lpath) { yield }
	end
	
	#------------------------------------------------------------------------------------------

	def up_to_date?
		remote_head = Bento.fread(@gpath/"refs/heads/master")
		local_head = Bento.fread(@lpath/".git/ORIG_HEAD")
		remote_head == local_head
	end
end

#----------------------------------------------------------------------------------------------

end # module Bento

___=<<END
-----------------------------------------------------------------------------------------------

cfiles = Bento.ControlledFiles(app, relpath)
	=> state may be inconsistent
f1 = cfiles["f1"] => git status, ...
cfiles.refresh
	=> check local changes
	=> check remote changes
	=> sync remote->local (may fail due to conflicts)
	=> sync local->remote

cfiles = Bento::ControlledFiles.create(app, relpath, source)

-----------------------------------------------------------------------------------------------
END
