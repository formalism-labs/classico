
require 'minitest/autorun'
require 'Bento'

class Test1 < Minitest::Test
	def setup
		@db = Bento::SQLite::DB.create() << <<~SQL
			create table numbers (name varchar(30), val int);
			SQL
	end

	def test_insert
		bb
		@db.execute("insert into numbers values (?, ?)", ['jojo', 17])
		assert_equal 'jojo', @db["select * from numbers where val = ?", 17][:name]
	end
end
