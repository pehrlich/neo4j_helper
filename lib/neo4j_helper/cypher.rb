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

      def match(str)
        self.cypher.match(str)
      end

      class Cypher

        def initialize(node, query = nil, options={})
          @node = node

          # todo: options such as as: :java or as: :ruby
          @query = query

          # todo: metaprogram this shiznit?
          @start = nil
          @match = nil
          @where = []
          @limit = nil
          @order = nil
          @skip = nil
          # note that this can be either an array or a string
          @returnables = nil
          @return_as = nil
          @formatter = nil # todo: deprecate?
          @results = nil
        end

        def results

          unless @results
            # memoize.  Important b/c method_missing uses this

            unless @query
              @start = "self = node(#{@node.neo_id})" unless @start
              @query = "START #{@start} MATCH #{@match} "
              @query << " WHERE #{@where.join ' AND '} " if @where.present?
              @query << " RETURN #{@returnables.join(', ')} "
              @query << " ORDER BY #{@order} " if @order
              @query << " SKIP #{@skip} " if @skip
              @query << " LIMIT #{@limit} " if @limit
            end

            # note: there are many cases where we won't need wrapping, such as for determining rel_type
            # but for now, this is premature optimization

            # paths cannot be wrapped
            # todo: figure out any practical application of paths

            p "Cyphering: #{@query}"
            # this gives us an array of complex hashes:
            # [ {condiment: {id: 1, name: 'Ketchup', _classname: "Condiment"}, flavoring: {id: 32, rel_type: :thick_spread} }, ...]
            @results = Neo4j.query(@query).map do |row|
              out = {} # move to a real hash!
              row.each do |key, value|
                #row.delete(key) # Java::JavaLang::UnsupportedOperationException: remove
                #key[key.to_sym] Java::JavaLang::UnsupportedOperationException: 	from java.util.AbstractMap.put(AbstractMap.java:186)
                out[key.to_sym] = (@return_as != :java and value.respond_to?(:wrapper)) ?
                    value.wrapper :
                    value
              end
              out
            end

            # if we're given a block @formatter, we allow it to reformat these results
            if @formatter
              # todo: check if
              @results = yield(@formatter, @results)
            end

          end

          @results
        end

        def clear_cache
          @results = nil
        end

        def paginate(options = {})
          clear_cache

          @limit = options[:per_page] || @limit || 7
          if options[:skip] # don't set skip if neither of these are specified
            @skip = options[:skip]
          elsif options[:page]
            @skip = options[:page].to_i * @limit.to_i
          end
          mapped
        end

        #returning is an array of args to be returned
        # by default, this flattens that complex hash
        # [[{id: 1, name: 'Ketchup'}, {id: 32}], [...], ...]
        # or, if possible
        # [{id: 1, name: 'Ketchup'}, {id: 7, name: 'Mustard'}, {...}, ...]
        # all options will be forwarded to #returning
        def mapped(*returnables)
          # note that compact is used at the end, because a blank query (sometimes?) returns for example {post: nil}

          returning(*returnables) if returnables.present?

          # todo: SUM, COUNT etc
          # but not TYPE, etc
          # are downcased when made in to keys.  This is likely a neo4jrb bug, and we could correct for it
          #@returnables = @returnables.map{ |r| r.to_s.gsub}

          mapped = self.results.map do |row|
            out = @returnables.map { |returnable| row[returnable] }
            out.length == 1 ? out[0] : out # unrwap array if possible # todo: better way?
          end.compact

          if @return_as.is_a?(Class)
            mapped = mapped.map { |row| @return_as.new(row) }
          end

          mapped
        end

        def start(string)
          clear_cache
          @start = string
          self
        end

        def match(string)
          clear_cache
          @match = string
          self
        end

        # this allows us to base one query off of another
        def continue_match(string)
          clear_cache
          @match = @match + string
          self
        end

        # where can be called multiple time in succession, and all where clauses will be used
        def where(string)
          clear_cache
          @where << string
          self
        end

        def limit(string)
          clear_cache
          @limit = string
          self
        end

        def skip(string)
          clear_cache
          @skip = string
          self
        end

        def order(string)
          clear_cache
          @order = string
          self
        end

        # accepts an array of symbols, or a custom string
        # .returning(:person, :hobbit)
        # .returning('person, axe, gnome')
        # accepts the as: parameter, which specifies how the content should be delivered
        # can be one of :ruby, :java, or a class.  When given a class, that class will
        # be passed the parameters suffixing a call to #mapped or #paginate (which uses mapped)
        # .returning(:person, :involvement, {as: Tuple})
        # by default, objects are returned as their ruby classes. If a as: class is specified, there
        # is no way to request java objects.
        def returning(*returnables, &block)
          clear_cache

          options = returnables.last.is_a?(Hash) ? returnables.pop : {}

          @returnables = returnables if returnables.present?
          @return_as = options[:as]
          @formatter = block

          self
        end


        protected


        def method_missing(symbol, *args)
          # benefits:
          # - we don't need to know what results are,
          # - we need to enumerate here the relevent methods
          # drawbacks:
          #  - results may be called unintentionally, for example in a typo making a partially constructed query,
          # leading to very confusing results.
          # we don't want to calculate results to see if they have the method, and so create a dummy enum
          if ({}.enum_for).respond_to? symbol
            results.send(symbol, *args)
          else
            super
          end
        end

      end
    end
  end
end