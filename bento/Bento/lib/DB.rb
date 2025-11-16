
require 'sqlite3'
require 'json'
require 'linguistics'

module Bento
module SQLite

#----------------------------------------------------------------------------------------------

class ColName
	def initialize(name)
		@name = ColName.fix(name)
	end

	def to_s
		@name
	end

	def self.fix(name)
		if name[/-/]
			"'#{name}'"
		else
			name
		end
	end
end

#----------------------------------------------------------------------------------------------

class ColSpec
	include Enumerable

	# hash = { colname => type, ... }
	def initialize(hash = {})
		@hash = hash.is_a(Hash)
	end

	def names
		@hash.keys
	end

	def type(col)
		@hash[col]
	end

	def[](col)
		type(col)
	end

	def create_table_exp
		exp = names.map{|c| "#{c} #{type(c)}"}
		"(#{colexp.join(', ')})"
	end

	def self.fix_colname(name)
		name.to_s.gsub(/-/, "_")
	end
end

#----------------------------------------------------------------------------------------------

class Value
	def self.fix(x)
		if x.is_a?(Numeric)
			x.to_s#.encode("ASCII-8BIT")
		elsif x.is_a?(String)
			x#.encode("ASCII-8BIT")
		elsif x.is_a?(TrueClass)
			"1"
		elsif x.is_a?(FalseClass)
			"0"
		elsif x.is_symbol?
			x.to_s#.encode("ASCII-8BIT")
		else
			x.to_s#.encode("ASCII-8BIT")
		end
	end
end

#----------------------------------------------------------------------------------------------

class Selector
	attr_reader :where, :params

	def initialize(query, *values)
		if query.array?
			@where = query[0].to_s
			@params = query[1..-1] + values
		else
			@where = query.to_s
			@params = values
		end
	end
end

#----------------------------------------------------------------------------------------------

class DB
	include Bento::Class

	constructors :is, :create, :create_from_nash

	attr_reader :path, :db

	#------------------------------------------------------------------------------------------

	private def _set_path(p1, p2)
		error "multiple files specified: '#{p1}' and '#{p2}'" if p1 != p2 && (p1 && p2) != nil
		@path = p1 || p2
	end

	private def _init(*opt)
		create = opt.include? :create

		if create
			if @temp
				@file = Tempfile.new('db')
				@path = @file.path
				@file.close(unlink_now: false)
				File.unlink(@path)
				dbspec = @path
			elsif @path == nil
				dbspec = ':memory:'
			else
				if !@force
					error "file exist: #{@path}" if File.exist?(@path)
				else
					begin
						File.unlink(@path) if File.exist?(@path)
					rescue
						error "Cannot delete #{@path}. Probably locked.", source: -2
					end
				end
				dbspec = @path
			end
		else
			dbspec = @path
		end

		@db = SQLite3::Database.new(dbspec)
		@db.results_as_hash = true

		@encoding = val("pragma encoding")
	end
	
	#------------------------------------------------------------------------------------------

	def is(p = nil, *opt, path: nil, schema: nil, data: nil)
		flags binding, [], withdefaults: [:p]

		_set_path(p, path)
		@schema = schema
		@data = data
		_init
	end
	
	#------------------------------------------------------------------------------------------

	def create(p = nil, *opt, path: nil, schema: nil, data: nil)
		flags binding, [:temp, :force], withdefaults: [:p]

		_set_path(p, path)

		_init(:create)

		@db.execute_batch(File.read(schema)) if schema != nil
		@db.execute_batch(File.read(data)) if data != nil

		info "database #{path} created"
	end

	#------------------------------------------------------------------------------------------

	def create_from_nash(nash, *opt, path: nil, table_name: "t1")
		flags binding, [:temp, :force]

		@path = path
		_init(:create)

		nash(table_name).set(nash)
	end

	#------------------------------------------------------------------------------------------

	def close
		@db.close
	end

	#-------------------------------------------------------------------------------------------

	def execute(*args)
		Results.new(@db.execute(*args))
	end

	def rows(*args)
		execute(*args)
	end
	
	def [](*args)
		rows(*args)
	end

	def <<(*args)
		@db.execute_batch(*args)
		self
	end

	def single(*args)
		Result.new(@db.get_first_row(*args))
	end
	
	alias_method :one, :single
	alias_method :row, :single

	def val(*args)
		one(*args)[0]
	end

	#-------------------------------------------------------------------------------------------

	def self.sql_values(values)
		values.map {|x| 
			x.is_a?(Numeric) ? x : 
			x.is_a?(TrueClass) ? 1 :
			x.is_a?(FalseClass) ? 0 :
			x.to_s }
	end
	
	#-------------------------------------------------------------------------------------------

	def insert(table, cols, *values)
		sql_values = DB.sql_values(values).map {|s| s.string? ? s.encode(@encoding) : s }
		qmarks = (["?"] * values.count).join(",")
		col_s = cols.map(&:to_s).join(",")
		insert = "insert into #{table.to_s} (#{col_s}) values (#{qmarks})"
		execute(insert, *sql_values)

		@inserted_table = table.to_s
		@inserted_id = single("select last_insert_rowid() as id;")[:id] rescue ''
	end

	def inserted
		one("select * from #{@inserted_table} where id=?", @inserted_id)
	end

	#-------------------------------------------------------------------------------------------

	# selector = [query-string, *values]
	def update(table, selector, cols, *values)
		selector.is_a(Array)
		values.concat(selector[1..-1])
		sql_values = DB.sql_values(values)
		col_s = cols.map{|x| x.to_s + "=?"}.join(",")
		update = "update #{table.to_s} set #{col_s} where #{selector[0]};"
		execute(update, *sql_values)
	end
	
	#-------------------------------------------------------------------------------------------

	def delete(table, query, *values)
		sql_values = DB.sql_values(values)
		delete = "delete from #{table.to_s} where #{query.to_s};"
		execute(delete, *sql_values)
	end

	#-------------------------------------------------------------------------------------------

	def create_table(name, colspec)
		Table.create(self, name, colspec)
	end

	#-------------------------------------------------------------------------------------------

	def table(name)
		SQLite.Table(self, name)
	end

	def nash(name)
		SQLite.NashTable(self, name)
	end

	#-------------------------------------------------------------------------------------------

	def dump
		systemx("sqlite3 #{path} .dump").out_s
	end
	
	#-------------------------------------------------------------------------------------------

	def transaction(desc = nil)
		begin
			info "transaction: #{desc.to_s}" if desc
			@db.transaction
			yield
			@db.commit
		rescue Exception => x
			@db.rollback
			if desc
				error "transaction rolled back: #{desc.to_s}"
			else
				error "transaction rolled back"
			end
    	end
	end

	#------------------------------------------------------------------------------------------

end # class DB

#----------------------------------------------------------------------------------------------

class Table
	include Bento::Class

	constructors :is, :create

	attr_reader :db, :name

	def is(db, name)
		@db = db.is_a(Bento::SQLite::DB)
		@name = name.to_s
	end

	def create(db, name, colspec)
		@db = db.is_a(Bento::SQLite::DB)
		@name = name.to_s
		if colspec.hash?
			colspec = ColSpec.new(colspec)
		elsif colspec.array?
			colspec = ColSpec.new(colspec.reduce({}) {|h, x| h[x] = "text"; h})
		end
		colexp = colspec.is_a(ColSpec).names.map{|c| "#{c} #{colspec[c]}"}
		@db << "create table #{name} (#{colexp.join(', ')});"
	end

	def colnames
		return @cols if @cols
		cols = @db["pragma table_info('#{@name}')"].raw.map {|x| x["name"]}
		@cols = cols.map{|c| ColName.fix(c)}
	end

	def create_columns(colspec)
		colspec.is_a(ColSpec)
		undef_cols = colspec.names - colnames
		commands = undef_cols.map { |c| "alter table #{name} add column #{c} #{colspec.type(c)};" }
		@db << commands.join("\n") if !commands.empty?
		@cols.concat(undef_cols)
	end

	def exist?
		@db["pragma table_info('#{@name}')"].count > 0
	end

	def update(*opt)
		@db.update(name, *opt)
	end

	def insert(*opt)
		@db.insert(name, *opt)
	end
end

#----------------------------------------------------------------------------------------------

class Result
	def initialize(result)
		@result = result
	end
	
	def [](x)
		@result[x.number? ? x : x.to_s]
	end

	def !()
		@result == nil
	end
end

#----------------------------------------------------------------------------------------------

class Results
	include Enumerable
	
	def initialize(results)
		@results = results
	end
	
	def raw
		@results
	end

	def [](x)
		if x.number?
			Result.new(@results[x])
		else
			@results[0][x.to_s]
		end
	end

	def ord(i)
		@results[i]
	end

	def each
		@results.each { |x| yield Result.new(x) }
	end

	def cut(name = nil)
		if !name
			c = cols
			if c.count == 1
				name = c[0]
			else
				return @results
			end
		end
		@results.map { |x| x[name] }
	end

	def cols
		result = @results[0]
		result == nil || !result.hash? ? [] : result.keys.select{|k|!k.number?}
	end

	def count
		!@results ? 0 : @results.count
	end

	def !()
		@results == nil
	end
end

#----------------------------------------------------------------------------------------------

class Query
	attr_reader :db

	def initialize(db, sql)
		@db = db
		@stmt = @db.execute(sql)
		@param = 0
	end

	def<<(x)
		@stmt.bind_param ++@param, x
		self
	end
	
	def exec!
		@stmt.execute
	end
end

#----------------------------------------------------------------------------------------------

end # module SQLite
end # module Bento
