
module Bento

#----------------------------------------------------------------------------------------------

class TagQuery
	Self = self

	attr_reader :names

	@@defaults_t = <<~END
		<% for c in query_tags %>
		var <%= c %> = 0;
		<% end %>

		if (!["number", "boolean"].includes(typeof(<%= @query %>)))
		{
			//throw "error";
			process.exit(1);
		}
		END

	@@func_t = <<~END
		function <%= name %>()
		{
		<% for c in obj_tags_commands %>
			var <%= c %>;
		<% end %>

			//return (<%= @query %>) && ["number", "boolean"].includes(typeof(<%= @query %>));
			return <%= @query %>;
		}

		if (<%= name %>()) console.log('<%= name %>');

		END

	def initialize(objects, query)
		@query = Self.fix_tags(query)
		
		@objects = objects.reduce({}) do |h, (k,v)|
			k = k.to_s
			if v.array?
				h[k] = Bento.keyhash(v.map{|t| Self.fix_tags(t)})
			elsif v.hash?
				h[k] = v.reduce({}) { |g, (j,w) | g[Self.fix_tags(j)] = w; g }
			elsif v.string? || v.symbol?
				h[k] = { v.to_s => 1 }
			end
			h
		end

		query_tags = @query.scan(/[_A-Za-z]\w+/).uniq

		js = Bento.mold(@@defaults_t)
		@objects.each do |name, tags|
			tags = Set[*tags].to_a
			obj_tags_commands = tags.map{|n,v| "#{n} = #{v}"}

			func = Bento.mold(@@func_t)
			js << func
		end

		# puts js
		
		cmd = <<~END
			node -e "base64 = require('base-64'); eval(base64.decode(process.argv[1]))" "#{Base64.strict_encode64(js)}"
			END

		if Bento::System.ostype == :windows
			if cmd.length < 500
				results = `#{cmd}`
			else
				results = systemx("source #{Bento.tempfile(cmd)}").out_s
			end
		else
			results = `#{cmd}`
		end
		@names = results.lines.map { |x| x.strip }
		error "could not query tags" if !$?.success?
	end
	
	def self.fix_tags(t)
		t.gsub(/[-.:]/,"_")
	end
end

#----------------------------------------------------------------------------------------------

end # module Bento
