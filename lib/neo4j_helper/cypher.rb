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

          @start = nil
          @match = nil
          @returning = nil
        end

        def results
          @query ||= "START #{@start} MATCH #{@match} RETURN #{@returning}"
          p "sending cypher query:"
          p @query
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


        def start(string)
          @start = string
          self
        end

        def match(string)
          @match = string
          self
        end

        def mapped(*returnables)
          unless @start
            @start = "self = node(#{@node.neo_id})"
          end
          @returning = returnables.join(', ') #returning is an array of args to be returned
          results.map do |row|
            out = returnables.map { |returnable| row[returnable] }
            out.length == 1 ? out[0] : out # unrwap if short # todo: better way?
          end
        end

        # ret(user: {rel: :rel})
        # takes a data structure to format the results in to?
        # ret(Tuple)
        # calls Tuple.new(*args)
        #def returning(string)
        #  @returning = "RETURN #{string}"
        #end

      end
    end
  end
end