module Neo4j
  module Rails
    module Finders

      class QueryBuilder
        # for now. where and fulltext not to be used in conjunction
        # multiple where's ok
        # multiple fulltext's not ok

        # note:
        # id is not indexed in lucene by default, a native finder is used there
        # we cannot used id:* to get all nodes.

        # todo: implement with LuceneQuery class directly?

        def initialize(node, remote_node = nil, dir = :incoming)
          # todo: default dir of both?
          @node = node

          raise "Invalid base node/model. Must repond to #all" unless node.respond_to? :all

          @query = {}
          @desc = []
          @asc = []

          @origin_node = remote_node
          @dir = dir
        end

        def limit(limit)
          @query[:per_page] = limit
          self
        end

        def page(page)
          # lucene starts at 1
          @query[:page] = page
          self
        end

        # for example
        # order(created_at: :desc)
        # this can be used with no other query, and it will find all
        # Signup.finder.order(created_at: :desc).all
        def order(hash_or_array)

          if hash_or_array.is_a? Hash
            fields = Array.wrap hash_or_array.keys.first
            order = hash_or_array.values.first
          else
            fields = Array.wrap hash_or_array
            order = :desc
          end

          if order == :desc
            @asc = []
            @desc.concat fields
          elsif order == :asc
            @desc = []
            @asc.concat fields
          else
            raise "required asc/desc, given: #{order}"
          end

          if @queryText.blank?
            # set default search
            @queryText = "#{fields.first}:*"
          end

          self
        end

        # acceps
        def fulltext(arg, options = {fuzzy: false, partial_words: false})
          # we can do a bit of lucene query building here
          # to learn more: http://lucene.apache.org/java/3_0_0/queryparsersyntax.html

          #> Goal.all('name_upcase:(new OR name)', :type => :fulltext).map &:name
          # => ["new name", "name"]

          # todo: admire mongoid docs and improve/expand this method


          # todo: searching multiple fields



          if arg.is_a? String
            # name: *bob*~
            query = hash
          end

          if arg.is_a? Hash
            field = arg.keys.first
            value = arg.values.first

            joiner = " OR "

            if value.is_a? String
              #:name => 'a b c'
              terms = value.split
              joiner = ' '
            end

            if value.is_a? Array
              #:name => ['a', 'b', 'c']
              # we're all set
              terms = value
            end

            if value.is_a? Hash
              #:name => {:any => ['a', 'b', 'c']}
              #:name => {:fuzzy => true, :any => ['a', 'b', 'c']}

              value.keys.each do |key|
                case key
                  when :any
                    joiner = " OR "
                    terms = Array.wrap value[key]
                  when :all
                    joiner = " and "
                    terms = Array.wrap value[key]
                  when :fuzzy
                    options[:fuzzy] = value[key]
                  when :partial_words
                    options[:partial_words] = value[key]
                  else
                    raise "unknwon key: #{key}"
                end
              end

            end

            raise "Invalid terms: `#{terms}'" unless terms.is_a?(Array) && terms.length > 0

            # both word*~ and word~* are fine

            # escape: + - && || ! ( ) { } [ ] ^ " ~ * ? : \
            # todo: && || \
            terms.map { |t| t.gsub!(/["\+\-\(\)\{\}\[\]\^\~\*\:\!]/, '') }

            terms.map! { |t| '*' << t << '*' } if options[:partial_words]

            terms.map { |t| t << '~' } if options[:fuzzy]

            query = "#{field}:(#{terms.join joiner})"
          end

          p "setting fulltext query: #{query}"
          @queryText = query
          @query[:type] = :fulltext
          self
        end

        def where(options)
          #  @query[:fulltext] = nil
          #  (@query[:where] ||= {}).merge! hash
          if options.is_a? String
            @queryText = options
          else

            raise 'non-string #where query not implemented'
          end
          self
        end

        # Match all people with either Bond or 007 as aliases.
        def any_in(options)
          @queryText = ''
          return also_in(options)
        end

        def also_in(options)
          if options.is_a? Fixnum
            options = Array.wrap Fixnum
          end
          if options.is_a? Array
            options = {id: options}
          end
          options.each do |prop, terms|
            # currently, id is different, being outside of a lucene index, but still searchable.
            # the way this is handled here is pretty dumb-- the return value is quite different from usual
            return find_by_ids(terms) if prop == :id

            (@queryText ||= '') << Array.wrap(terms).map do |term|
              "#{prop}:(#{term})"
            end.join(' OR ')

          end
          self
        end

        def find_by_ids(ids)

          results = Array.wrap(ids).map do |id|
            @node.find(id: id)
          end

          results.compact
            #query = self.find(field => values.shift)
      #  #
      #  #values.each do |value|
      #  #  logger.warn "adding to query: or #{value}"
      #  #  query.or(field => value)
      #  #end
      #  #
      #  #query
        end

        def to_enum
          # this does the search
          # can we use #all here?
          # todo: we could also memoize here
          p "@queryText : #{@queryText}"
          p @query

          #Goal.all("name_upcase: #{name.upcase}", :per_page => limit, :page => page, :type => :fulltext)

          raise 'No query given' unless @queryText.present?

          result_nodes = @node.all(@queryText, @query)

          if @asc.present?
            result_nodes.asc(*@asc)
          end

          if @desc.present?
            result_nodes.desc(*@desc)
          end

          if @origin_node.present?
            # origin node, for example: current_user
            result_nodes.map { |result_node|
              # there's no easy way to get both here
              # rels_dsl#to_other -> storage#to_other
              # no way to set direction in rels dsl, despite storage having #relationships which takes @dir

              # tuple currently doesn't support multiple rels anyway

              if @dir == :outgoing
                Neo4j::Rails::Relationships::Tuple.new(result_node, @origin_node.rels_to(result_node).all)
              elsif @dir == :incoming
                Neo4j::Rails::Relationships::Tuple.new(result_node, result_node.rels_to(@origin_node).all)
              else
                raise "rel dir #{@dir} not supported :-("

                rels = result_node.rels_to(@origin_node).all
                rels.concat @origin_node.rels_to(result_node).all
                Neo4j::Rails::Relationships::Tuple.new(result_node, rels)

              end

            }
          else
            result_nodes
          end
        end

        # todo: remove?
        def find(id)
          self.where({:id => id})
          self.first
        end

        def find_by(hash)
          #self.where(hash)
          #self.first
          # supports  User.find_by(:email => email) :
          @node.find(hash)
        end

        def all
          # all not implemented on enum
          self.to_enum.to_a
        end

        # override inherited version
        delegate :to_json, :to => :to_enum

        def method_missing(symbol, *args)
          @e ||= {}.enum_for
          if @e.respond_to? symbol
            # do the query:
            results = self.to_enum
            results.send(symbol, *args)
          else
            super
          end
        end

      end

      module ClassMethods
        # ie, Goal.tuples(current_user)
        # unlike the case of Goal.users.tuples, where the goal is constant and the users are changing with every rel,
        # here the current_user is constant and the goal is changing with every rel

        def tuples(options = {})
          # todo: default dir of both
          # todo: updated tuples method in other dsl w/ to and from

          if node = options[:to]
            QueryBuilder.new(self, node, :outgoing)
          elsif node = options[:from]
            QueryBuilder.new(self, node, :incoming)
          elsif  node = options[:both] || node = options[:about]
            # note: not implemented in qb
            QueryBuilder.new(self, node, :both)
          else
            QueryBuilder.new(self)
          end

        end

        def finder
          QueryBuilder.new(self)
        end

      end

    end
  end
end

module Neo4j
  module Rails
    Model.class_eval do
      # re-running class eval
      include Finders
    end
  end
end