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

        # todo: we take an origin node and use origin_node.rels_to(<found node>)
        # will this get rels in both directions? Should it? Should it be a setting?

        def initialize(model, remote_node = nil, dir = :incoming)
          # todo: default dir of both?
          @model = model

          raise "Invalid base node/model. Must repond to #all" unless model.respond_to? :all

          @query = {}
          @desc = []
          @asc = []
          #@origin_node = options[:tuples_from].presence
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

        def fulltext(arg)
          # we can do a bit of lucene query building here
          # to learn more: http://lucene.apache.org/java/3_0_0/queryparsersyntax.html

          #> Goal.all('name_upcase:(new OR name)', :type => :fulltext).map &:name
          # => ["new name", "name"]

          # todo: admire mongoid docs and improve/expand this method

          # todo: escape and test: + - && || ! ( ) { } [ ] ^ " ~ * ? : \

          # todo: searching multiple fields


          if arg.is_a? String
            # name: *bob*~
            query = hash
          end

          if arg.is_a? Hash
            field = arg.keys.first
            value = arg.values.first

            joiner = " OR "
            partial_words = true
            fuzzy = true

            if value.is_a? String
              #:name => 'a b c'
              terms = value.split
            end

            if value.is_a? Array
              #:name => ['a', 'b', 'c']
              # we're all set
              terms = value
            end

            if value.is_a? Hash
              #:name => {:any => ['a', 'b', 'c']}

              value.keys.each do |key|
                case key
                  when :any
                    joiner = " OR "
                    terms = value[key]
                  when :all
                    joiner = " and "
                    terms = value[key]
                  when :fuzzy
                    fuzzy = value[key]
                  when :partial_words
                    partial_words = value[key]
                  else
                    raise "unknwon key: #{key}"
                end
              end

            end

            raise "Invalid terms: `#{terms}'" unless terms.is_a?(Array) && terms.length > 0

            # both word*~ and word~* are fine

            terms.map! { |t| '*' << t << '*' } if partial_words

            terms.map! { |t| t << '~' } if fuzzy

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

        def to_enum
          # this does the search
          # can we use #all here?
          # todo: we could also memoize here
          p "@queryText : #{@queryText}"
          p @query

          #Goal.all("name_upcase: #{name.upcase}", :per_page => limit, :page => page, :type => :fulltext)

          result_nodes = @model.all(@queryText, @query)

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

        def find(id)
          self.where({:id => id})
          self.first
        end

        def find_by(hash)
          self.where(hash)
          self.first
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

        def tuples(options)
          # todo: default dir of both
          # todo: updated tuples method in other dsl w/ to and from

          if node = options[:to]
            QueryBuilder.new(self, node, :outgoing)
          elsif node = options[:from]
            QueryBuilder.new(self, node, :incoming)
          elsif  node = options[:both] ||  node = options[:about]
            # note: not implemented in qb
            QueryBuilder.new(self, node, :both)
          else
            QueryBuilder.new(self)
          end

        end

        def builder_find
          QueryBuilder.new(self)
        end

      end

      # broken
      #module InstanceMethods
      #
      #  def rels_to(node)
      #    self.rels.to_other(node)
      #  end
      #
      #end

    end
  end
end

module Neo4j
  module Rails
    Model.class_eval do
      # re-running class eval
      include Finders # ActiveRecord style find
    end
  end
end