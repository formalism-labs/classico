
require 'set'

module Bento

#----------------------------------------------------------------------------------------------

class Box
	include Bento::Class

	constructors :is, :create
	members :id, :root, :app #, :source

	attr_reader :id, :root, :source, :app, :apps, :test

	#------------------------------------------------------------------------------------------

	def is(id = nil, *opt, app: nil)
		flags binding, []

		id = ENV["BOX"] if !id
		error "no default box" if !id

		begin
			@id = id
			@root = Box.root_path(@id)
			@app = _guesss_app(app)
			
			config = read_cfg

			@test = config["test"] || false

			@apps = Set.new(config["apps"])
			@apps += [@app] if self.app

			__ready

		rescue => x
			error "invalid box: '#{id}"
		end
	end

	#------------------------------------------------------------------------------------------

	def create(*opt, app: nil, source: nil)
		flags binding, [:test]

		@id = Box.make_id
		@root = Box.root_path(@id)
		@app = _guesss_app(app)
		@apps = Set.new(@app ? [@app] : [])
		@test = !!@test

		error "Box @id exists: aborting" if File.exists?(root)
		
		Bento.mkdir(root)

		source = Bento.module_root(self) if !source
		if source
			source /= :test if @test

			@source = source
		end
		create_fs

		write_cfg

		__ready

		puts "created box #{id}" if !test?

		rescue => x
			remove! rescue ''
			error "failed to create box, due to: #{x.to_s}"
	end

	#------------------------------------------------------------------------------------------

	def name
		id
	end

	def self.make_id
		id = Time.now.strftime("%y%m%d-%H%M%S")
		while File.directory?(Boxes.root/id)
			id = Time.now.strftime("%y%m%d-%H%M%S%L")
		end
		id
	end

	def self.root_path(id)
		Boxes.root/id
	end
	
	def data_path
		root
	end

	def app_root(app = nil)
		app = @app if !app
		return nil if !app
		root/app.to_s
	end

	def test?
		@test
	end
		
	#------------------------------------------------------------------------------------------
	
	def self.config_file(id)
		Boxes.root/id/"box.json"
	end

	def config_file
		Box.config_file(id)
	end

	def read_cfg
		JSON.from_file(config_file)
	end

	def write_cfg
		config = {
			"id" => @id,
			"apps" => @app ? (@apps + [@app]).to_a : @apps.to_a,
			"test" => @test }
		JSON.from_json(config).save(config_file)
	end

	#------------------------------------------------------------------------------------------

	def self.find(id = nil, app: nil, obj: nil)
		obj = self if !obj

		id = ENV["BOX"] if !id
		return nil if !id

		root = Box.root_path(id)
		return nil if !Dir.exist?(root)
		return nil if !File.exist?(Box.config_file(id))

		box_class = eval("#{obj.module.name}::Box") rescue nil
		box_class ? box_class.is(id, app: app) : Bento.Box(id, app: app)
	end

	#------------------------------------------------------------------------------------------

#	def db_name
#		self.class.name.downcase
#	end

#	def db_path
#		root/"db"/"#{db_name}.db"
#	end

	def log_root
		root/:logs
	end

	#------------------------------------------------------------------------------------------
	# Construction
	#------------------------------------------------------------------------------------------

	def create_fs
		Bento.mkdir(root/:logs)
	end

	def copy_source_fs1
		fs_root = root
		fs_root /= app if app
		Bento.mkdir(fs_root)

		if File.extname(source) == ".zip"
			error "source #{source} does not exist" if !File.exist?(source)
			Bento.unzip(source, fs_root)

		else
			source = self.source/:skel
			if Dir.exist?(source)
				error "source #{source} is not a directory" if !File.directory?(source)
				# copy content of source, not source itself
				Bento.cp_r(source + "/.", fs_root)
				Bento.rm(Bento.find(fs_root).select{|f| File.basename(f) == "_" && !File.size?(f)})
			else
				error "cannot establish source #{source}" if source != nil
			end
		end
	end

	def copy_source_fs
		Box.copy_source_fs(root, app, source)
	end
	
	def self.copy_source_fs(root, app, source)
		fs_root = root
		fs_root /= app if app
		Bento.mkdir(fs_root)

		if File.extname(source) == ".zip"
			error "source #{source} does not exist" if !File.exist?(source)
			Bento.unzip(source, fs_root)

		else
			source /= :skel
			if Dir.exist?(source)
				error "source #{source} is not a directory" if !File.directory?(source)
				# copy content of source, not source itself
				Bento.cp_r(source + "/.", fs_root)
				Bento.rm(Bento.find(fs_root).select{|f| File.basename(f) == "_" && !File.size?(f)})
			else
				error "cannot establish source #{source}" if source != nil
			end
		end
	end

	#------------------------------------------------------------------------------------------
	# Removal
	#------------------------------------------------------------------------------------------

	def remove
		info "removing box #{id}"
		close
		write_cfg
		Boxes.remove(id)
		info "box #{id} removed"
	end
	
	def remove!
		info "removing box #{id}"
		close
		write_cfg

		abort = false
		failed_objects = []

		begin
			Bento.rm_r(@root)
		rescue => x
			failed_objects << "directory #{@root}"
		end

		error "box #{id} was not removed: #{failed_objects}" if abort
		info "box #{id} removed"
	end

	#------------------------------------------------------------------------------------------
	# Apps
	#------------------------------------------------------------------------------------------

	private def _guesss_app(name = nil)
		if !name
			name = self.class.class_eval("@@app_name") rescue nil
			name = self.module.name.downcase if !name
			name = nil if name == "bento"
		end
		name
	end

#	def apps
#		@config["apps"]
#	end

	def app_exist?(app)
		apps.include?(app) && File.exist?(root/app.to_s)
	end

	#------------------------------------------------------------------------------------------
	# Open/close
	#------------------------------------------------------------------------------------------

	def open
	end

	def close
	end

	#------------------------------------------------------------------------------------------
	# Enter
	#------------------------------------------------------------------------------------------

	def enter
		ENV["BOX"] = id
		Bento::Log.to = log_root/"#{File.basename($0, '.*')}.log"
		# appdata?
	end
	
end # class Box

#----------------------------------------------------------------------------------------------

class Boxes
	include Enumerable

	def initialize
		@names = Dir[(Boxes.root/'*').to_ux].select {|f| File.directory?(f)}.map {|f| File.basename(f)}.sort
	end

	def each
		@names.each { |name| yield Bento.Box(name) }
	end

	def print
		default_name = ENV["BOX"]
		each do |box|
			name = box.name
			puts name + (default_name == name ? " *" : "")
		end
	end
	
	def self.root
		root = ENV["BOXES_ROOT"]
		error "cannot establish boxes location" if !root
		Pathname.new(root)
	end

	def self.print
		Boxes.new.print
	end
	
	def self.remove(id)
		Bento.mkdir(Boxes.root/".attic")
		Bento.mv(Boxes.root/id.to_s, Boxes.root/".attic")
	end

end # class Boxes

#----------------------------------------------------------------------------------------------

end # module Bento
