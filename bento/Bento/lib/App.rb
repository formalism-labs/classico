
module Bento

#----------------------------------------------------------------------------------------------

class AppData
	include Bento::Class

	constructors :is, :create

	attr_reader :app_name
	attr_reader :box, :source
	attr_accessor :root
	attr_accessor :data_root, :host_root, :user_root, :hu_root, :local_root, :lu_root
	attr_accessor :cfg_root, :log_root, :db_root

	#------------------------------------------------------------------------------------------

	def is(name = nil, *opt)
		flags binding, []

		if name
			error "invalid app name: #{name}" if name !~ /^\w*$/ 
			@app_name = name.to_s
		end
	
		data_var = "#{app_name.upcase}_APPDATA"
		if ENV[data_var]
			@root = Pathname.new(ENV[data_var])
			error "data path for app '#{app_name}' does not exist: #{@root}" if !@root.exist?
		else
			box = Box.find(app: app_name, obj: self)
			if box
				@box = box
			else
				@box = create_box
			end
			@root = @box.app_root
		end

		# ENV[app_data] exists?
		# have an active box?
		# does app exist in box?

		set_paths
		
		# __ready
	end

	#------------------------------------------------------------------------------------------

	def set_paths
		host = Bento::System.hostname
		user = Bento::System.user

		@data_root = root
		@host_root = root/:net/host
		@user_root = root/:usr/user
		@hu_root = root/:net/host/:usr/user
		@local_root = root/:local
		@lu_root = root/:local/:usr/user
		
		@cfg_root = root/:cfg
		@log_root = root/:log
		@db_root = root/:db
	end
	
	#------------------------------------------------------------------------------------------

	def create(*opt, name: nil, source: nil, box: nil)
		flags binding, [:test]

		self.module.class_variable_set("@@creating_app_data", true)

		if name
			error "invalid app name: #{name}" if name !~ /^\w*$/ 
			@app_name = name.to_s
		end

		source = self.module.root if !source
		error "app data source not specified" if !source

		data_var = "#{app_name.upcase}_APPDATA"
		if v = ENV[data_var]
			@root = ~v
		else
			@box = box || Box.find(app: app_name, obj: self)
			if @box
				@root = @box.app_root
				source /= :test if @box.test?
			end
		end
		error "app data for #{app_name} already exists at #{@root}" if @root && @root.exist?

		@source = source
		AppData.copy_source_fs(@root, source)
		box.write_cfg if @box
		
		set_paths
		
		self.module.app_data = self
		
		# __ready

		ensure
			self.module.remove_class_variable("@@creating_app_data")
	end

	#------------------------------------------------------------------------------------------

	def self.copy_source_fs(fs_root, source)
#		fs_root = root/app_name
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

	alias_method :app_root, :data_root
	
	def self.app_name(obj)
		name = obj.class.class_eval("@@app_name") rescue nil
		name = self.module.name.downcase if !name
		name
	end

	def app_name
		if !@app_name
			name = self.class.class_eval("@@app_name") rescue ''
			name = self.module.name.downcase if !name
			@app_name = name
		end
		@app_name
	end
	
	#------------------------------------------------------------------------------------------

#	def find_box
#		b1 = Box.find
#		return nil if !b1
#		box_class = eval("#{self.module.name}::Box") rescue nil
#		box_class ? box_class.is(b1.id, app: app_name) : b1
#	end

	def create_box
		box_class = eval("#{self.module.name}::Box") rescue nil
		if box_class
			box_class.create(app: app_name)
		else
			Bento::Box.create(app: app_name)
		end
	end

	def test?
		@box && @box.test?
	end

	def serialize
		unimplemented
	end
	
	#------------------------------------------------------------------------------------------
	
	def config_file
		data_root/"#{app_name}.yaml"
	end

	def log_dir
	end
	
	def db_dir
		data_root/:db
	end
	
	#------------------------------------------------------------------------------------------

	# defines Module.app_data and Module.app_data=
	def self.inherited(klass)
		klass.module.module_eval(<<-END, __FILE__, __LINE__)
			def self.app_data
				mod = eval("#{klass.module.name}")
				klass_name = "#{klass.name}".split("::")[-1]
				if mod.class_variable_defined?("@@app_data")
					app_data = mod.class_variable_get("@@app_data")
				else
					creating = mod.class_variable_get("@@creating_app_data") rescue false
					app_data = creating ? nil : eval(mod.name + "." + klass_name + "()")
					mod.class_variable_set("@@app_data", app_data)
				end
				app_data
			end

			def self.app_data=(app_data)
				app_data.is_a(#{klass.name})
				mod = eval("#{klass.module.name}")
				mod.class_variable_set("@@app_data", app_data)
			end
			END
		super
	end

end

#----------------------------------------------------------------------------------------------

end # module Bento
