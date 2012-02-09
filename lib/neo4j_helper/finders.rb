module Neo4j
  module Rails
    module Finders

      class QueryBuilder
        # for now. where and fulltext not to be used in conjunction
        # multiple where's ok
        # multiple fulltext's not ok

        # todo: we take an origin node and use origin_node.rels_to(<found node>)
        # will this get rels in both directions? Should it? Should it be a setting?

        def initialize(node, options = {})
          @node = node

          raise "Invalid node. Must repond to #all" unless node.respond_to? :all

          @options = options
          @query = {}
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

        def order(hash)
          raise 'todo'
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
          @fulltext = query
          @query[:type] = :fulltext
          self
        end

        def where(hash)
          @query[:fulltext] = nil
          (@query[:where] ||= {}).merge! hash
          self
        end

        def to_enum
          # this does the search
          # can we use #all here?
          # todo: we could also memoize here

          #Goal.all("name_upcase: #{name.upcase}", :per_page => limit, :page => page, :type => :fulltext)
          if @query[:type] == :fulltext
            p "fulltext query: #{@fulltext}"
            p @query

            # for whatever reasons, @node is our rails model: Goal.all
            result_nodes = @node.all(@fulltext, @query)

            # origin node, for example: current_user
            if origin_node = @options[:tuples_from]
              result_nodes.map { |result_node|
                # todo: handle both rel directions? For example, the following would not work:
                #Neo4j::Rails::Relationships::Tuple.new(result_node, origin_node.rels_to(result_node).all)

                Neo4j::Rails::Relationships::Tuple.new(result_node, result_node.rels_to(origin_node).all)
              }
            else
              result_nodes
            end
          else
            raise 'non-fulltext queries not yet implemented'
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

        def tuples(origin_node)
          # node: other name, such as tuples_from or tuples_of could be considered
          # but they might imply only results w/ rels, which is not necessarily the case.
          QueryBuilder.new(self, {:tuples_from => origin_node})
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