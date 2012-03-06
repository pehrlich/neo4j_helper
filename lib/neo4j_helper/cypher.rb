module Neo4j
  module Rails
    class Model

      # one option would be to make methods for every hash item here (method_missing)
      # allowing     results.map &:post # convert to post array
      def cypher(string = nil, options = {})
        cypher = Cypher.new(self, string, options)
        # call results immediately if string given
        string.present? ? cypher.results : cypher
      end

      class Cypher

        def initialize(node, query = nil, options={})
          @node = node

          # todo: options such as as: :java or as: :ruby
          @query = query

          # todo: metaprogram this shiznit?
          @start = nil
          @match = nil
          @where = nil
          @limit = nil
          @order = nil
          @skip = nil
          @returnables = nil
        end

        def results

          unless @query
            @start = "self = node(#{@node.neo_id})" unless @start
            @query = "START #{@start} MATCH #{@match} "
            @query << " WHERE #{@where} " if @where
            @query << " RETURN #{@returnables.join(', ')} "
            @query << " ORDER BY #{@order} " if @order
            @query << " LIMIT #{@limit} " if @limit
            @query << " SKIP #{@skip} " if @skip
          end

          p "Cyphering: #{@query}"
          rows = Neo4j.query @query

          # note: there are many cases where we won't need wrapping, such as for determining rel_type
          # but for now, this is premature optimization

          # paths cannot be wrapped
          rows.map do |row|
            out = {} # move to a real hash!
            row.each do |key, value|
              #row.delete(key) # Java::JavaLang::UnsupportedOperationException: remove
              #key[key.to_sym] Java::JavaLang::UnsupportedOperationException: 	from java.util.AbstractMap.put(AbstractMap.java:186)
              out[key.to_sym] = value.respond_to?(:wrapper) ? value.wrapper : value
            end
            out
          end

        end

        def paginate(options)
          @limit = options[:per_page] || 7
          if options[:skip] # don't set skip if neither of these are specified
            @skip = options[:skip]
          elsif options[:page]
            @skip = options[:page].to_i * @limit.to_i
          end
          mapped
        end

        def mapped(*returnables)
          #returning is an array of args to be returned
          returning(*returnables) unless @returnables
          results.map do |row|
            out = @returnables.map { |returnable| row[returnable] }
            out.length == 1 ? out[0] : out # unrwap if short # todo: better way?
          end
        end


        def start(string)
          @start = string
          self
        end

        def match(string)
          @match = string
          self
        end

        def where(string)
          @where = string
          self
        end

        def limit(string)
          @limit = string
          self
        end

        def skip(string)
          @skip = string
          self
        end

        def order(string)
          p "setting order #{string}"
          @order = string
          self
        end

        def returning(*returnables)
          # todo: if a string is passed, what happens?
          @returnables = returnables if returnables.present?
          self
        end


      end
    end
  end
end