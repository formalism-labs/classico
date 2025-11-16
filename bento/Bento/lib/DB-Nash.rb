require 'sqlite3'
require 'json'
require 'linguistics'

module Bento
module SQLite

#----------------------------------------------------------------------------------------------

class HashSkel
	include Bento::Class
	
	constructors :from_hash, :from_array
	attr_reader :skel

	def from_hash(hash, *opt)
		flags binding, [:complex]
		@skel = _skel(_pack(hash))
	end

	alias_method :from_array, :from_hash

	private def _pack_item(v, name, pack)
		if v.string? || v.number? || v.bool?
			pack[name] = 1
		elsif v.hash?
			if @complex
				pack[name] = {}
				v.keys.each { |g| pack[name][g] = 1 }
			end
		elsif v.array?
			if @complex
				pack[name] = []
			end
		elsif v == nil
		else
			error "error in packing '#{v.to_s}'"
		end
	end

	# data is either hash[hash] or array[hash]
	private def _pack(data)
		pack = {}
		if data.hash?
			data.keys.each do |k|
				hash = data[k]
				hash.keys.each do |j|
					_pack_item(hash[j], j, pack)
				end
			end
		elsif data.array?
			data.each do |hash|
				hash.keys.each do |j|
					_pack_item(hash[j], j, pack)
				end
			end
		end
		pack
	end
	
	private def _skel(pack)
		skel = [:id, :name, :json]
		pack.keys.each do |f|
			sym = f.downcase.to_sym
			v = pack[f]
			if v.number?
				skel << sym
			elsif v.hash?
				skel << [sym] + v.keys.map(&:downcase).map(&:to_sym)
			elsif v == []
				skel << [sym, []]
			else
				error "error processing '#{v.to_s}'"
			end
		end
		skel
	end

	def colnames
		v = skel.select{|x| x.symbol?}.map{|x| ColName.fix(x)}
		if @complex
			compound = skel.select{|x| x.array? && x[1] != []}
			compound.each do |x|
				v += x.cdr.map{|f| ColName.fix("#{x.first}_#{f}")}
			end
		end
		v
	end

	def colspec
		c = colnames.reduce({}) { |h, x|
			x = x.to_s
			case x
			when "id"; y = "integer primary key autoincrement"
			when "name"; y = "text not null"
			else; y = "text"
			end
			h[x] = y; h }
		ColSpec.new(c)
	end
	
	def subtables
		if @complex
			skel.select{|x| x.array? && x[1] == []}.map(&:first).map(&:to_s)
		else
			[]
		end
	end
	
	def subtable_colspec_fields
		ColSpec.new({ "id" => "integer primary key", "name" => "text" })
	end
end

#----------------------------------------------------------------------------------------------

class NashTable
	include Bento::Class

	constructors :is, :create
	members :table

	#------------------------------------------------------------------------------------------

	def is(db, table_name)
		@table = SQLite.Table(db, table_name)
	end

	def create(db, table_name, nash = {})
		skel = HashSkel.from_hash(nash)
		@table = Table::create(db, table_name, skel.colspec)
		db << "create index #{table_name}_name on #{table_name} (name);"
		insert(nash)
	end

	#------------------------------------------------------------------------------------------

	def db
		@table.db
	end

	def table_name
		@table.name
	end

	alias_method :name, :table_name

	def exist?
		@table.exist?
	end

	def keys
		db["select name from #{table_name};"].cut
	end

	#------------------------------------------------------------------------------------------

	def set(nash, *flags)
		upsert = flags.include? :upsert

		skel = HashSkel.from_hash(nash)
		if !@table.exist?
			Table.create(db, table_name, skel.colspec)
			db << "create index #{table_name}_name on #{table_name} (name);"
			db_keys = []
		else
			@table.create_columns(skel.colspec)
			db_keys = keys
		end
		new_keys = nash.keys - ["\\#skel"]
		insert(nash, new_keys - db_keys)
		update(nash, new_keys & db_keys)
		delete(db_keys - new_keys) if !upsert
	end

	def upsert(nash)
		set(nash, :upsert)
	end

	#------------------------------------------------------------------------------------------

	def insert(nash, keys = nil)
		keys = nash.keys if !keys
		keys.each do |k|
			cols = []
			values = []
			v = nash[k]
			cols << "name" << "json"
			values << k << v.to_json
			v.keys.each do |j|
				w = v[j]
				if w.number? || w.string? || w.bool?
					cols << ColName.fix(j)
					values << Value.fix(w)
				end
			end
			db.insert(table_name, cols, *values)
		end
	end

	#------------------------------------------------------------------------------------------

	def update(nash, keys = nil)
		keys = nash.keys if !keys
		keys.each do |k|
			cols = []
			values = []
			v = nash[k]
			cols << "name" << "json"
			values << k << v.to_json
			v.keys.each do |j|
				w = v[j]
				if w.number? || w.string? || w.bool?
					cols << ColName.fix(j)
					values << Value.fix(w)
				end
			end
			db.update(table_name, ["name=?", k], cols, *values)
		end
	end

	#------------------------------------------------------------------------------------------

	def delete(keys)
		return if keys.empty?
		query = (["name=?"] * keys.count).join(" or ")
		db.delete(table_name, query, *keys)
	end

	#------------------------------------------------------------------------------------------

	def[](key)
		Record.new(self, key)
	end

	def[]=(key, hash)
		Record.new(self, key).set!(hash.is_a(Hash))
	end

	#------------------------------------------------------------------------------------------

	def to_h
		v = db["select name, json from #{@table.name};"]
		v.inject({}) { |h, x| h[x["name"]] = JSON.from_json(x["json"]).to_h; h }
	end

	alias_method :all, :to_h

	#------------------------------------------------------------------------------------------

	class Record
		attr_reader :key

		def initialize(nash, key)
			@nash = nash.is_a(NashTable)
			@key = key.to_s
			v = @nash.db.one("select json from #{@nash.table_name} where name=?;", @key)
			@hash = !v ? {} : JSON.from_json(v[0]).to_h
		end

		def exist?
			@hash != {}
		end

		def[](name)
			@hash[name.to_s]
		end

		def[]=(name, hash)
			hash.is_a(Hash)
			@hash[name.to_s] = hash
		end

		def delete(name)
			@hash.delete(name.to_s)
		end

		def method_missing(m, *args)
			m = m.to_s
			if m[-1] == "="
				m = m[0..-2]
				@hash[m] = args[0]
			else
				@hash[m]
			end
		end

		def to_h
			{ key => @hash }
		end

		def values
			@hash
		end

		def set(hash)
			@hash = hash.is_a(Hash)
		end

		def set!(hash)
			set(hash)
			update!
		end

		def update!
			@nash.upsert({@key => @hash})
		end
	end
end

#----------------------------------------------------------------------------------------------

end # module SQLite
end # module Bento
