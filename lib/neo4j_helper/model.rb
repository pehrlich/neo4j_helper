module Neo4j
  module Rails
    class Model

      # Channel.rels2(to: location)
      # Channel.rels2(:located, to: location)
      # Channel.rels2(to: 24)
      def rels2(type, options = {})
        # type is optinal parameter
        if type.is_a? Hash
          options = type
          type = nil
        end

        rel_type =  type ? ":#{type}" : ''
        # todo: allow both directions?

        cypher = self.cypher
        if end_node = options[:to]
          # todo: by default, to_other returns nodes in both directions, where we would expect it only to do outgoing.
          # in fact, there appears to be no easy way to specify direction here with neo4jrb, so we use cypher.
          # should we decide not to wrap nodes for speed?
          #rels = type ? self.rels(type) : self.rels
          #rels.to_other(end_node)
          #cypher.match("(self)-[rel#{rel_type}]->(node(#{end_node.neo_id}))").mapped(:rel)
          if end_node.is_a? Fixnum
            neo_id = end_node
          elsif !(neo_id = end_node.neo_id)
            raise "No id on :to node. Unpersisted? #{end_node.inspect}"
          end

          out = cypher.match("(self)-[rel#{rel_type}]->(end_node)").
              where("ID(end_node) = #{neo_id}").
              mapped(:rel)
        elsif start_node = options[:from]
          out = cypher.match("(self)<-[rel#{rel_type}]-(start_node)").
                        where("ID(start_node) = #{start_node.neo_id}").
                        mapped(:rel)
          #cypher.match("(self)<-[rel#{rel_type}]-(node(#{start_node.neo_id}))").mapped(:rel)
          #rels = type ? start_node.rels(type) : start_node.rels
          #rels.to_other(self)
        else
          out = self.rels(type)
        end

        # note that the relsdsl #rels returns does not have #length, #count must be used
        # note also that the above is a lie, and this doesn't appear to work as all for relsdsl
        out = out[0] if out.count == 1

        out
      end

      # returns the relation if related, else false
      def related?(type, options = {})
        rels2(type, options).presence
      end

      # todo: test update attributes change of classname
      def ensure_relation(type, options = {}, props = {})
        # options: to and from
        if rel = related?(type, options)
          if options[:class]
            # todo: dry this against internal methods
            props[:_classname] = options[:class].to_s
          end
          rel.update_attributes props
          rel
        else
          relate(type, options, props)
        end

      end

      # when given a chain of relations (such as a list of posts)
      # this takes
      # insert_relation(:newest_posts, to: new_post_node)
      # which will put new_post node at the top of the chain
      # currently only to: is accepted, meaning outgoing relationships from self
      # outgoing rels on the receiver and the to: node should be of the same type
      def insert_relation(rel_type, options)
        unless new_item = options[:to]
          raise "no :to parameter passed"
        end

        unless new_item.persisted?
          raise "cannot insert relation to unpersisted node: #{new_item}"
          # else
          # RuntimeError (node.rels(...).to_other() not allowed on a node that is not persisted):
          # when running ensure_relation
        end

        # fix up the old rel.  Start_node will no longer be me.

        #if old_rel = self.rels2(rel_type)
        if old_rel = self.rels(rel_type).first
          # neo4jrb does not allow us to change the start node on a persisted relationship
          # instead, it fails silently
          #rel.start_node = new_item # assumed in the :to direction

          new_item.ensure_relation(rel_type, to: old_rel.end_node)

          old_rel.delete
        end

        self.ensure_relation(rel_type, options)
      end

      def unrelate(type, options = {})
        if rels = rels2(type, options)
          # todo/neo4j: rels.delete_all
          # rels2 either returns a <Neo4j::Rails::Relationships::AllRelsDsl
          # or a <Neo4j::Rels::Traverser
          # the former responds to delete_all, the latter does not
          #rels.delete_all
          # rels2 returns either a single object or an array
          Array.wrap(rels).each &:delete
          # note, if nil is not returned here, rels, which doesn't exist, is.  Bugg!
          # todo.. should be deleted from neo4j identity map?
          nil
        end
      end

      # creates a relationship between two nodes
      # accepts :rel_class when making the relationship
      # currently doesn't read declared relationships to find rel class
      # to do so, it would have to look them up by rel type and then find the rel class
      def relate(type, options = {}, props = {})
        if end_node = options[:to]
          start_node = self
        elsif start_node = options[:from]
          end_node = self
        else
          raise ':to or :from is required'
        end
        klass = options[:class] ||  Neo4j::Rails::Relationship
        klass.create(type, start_node, end_node, props)
      end

      # todo: deprecate in favor of rels2
      def rels_to(end_node, options = {})
        if type = options[:type]
          rels(type).to_other(end_node)
        else
          self.rels.to_other(end_node)
          # self.rels2(options[:type], {to: end_node}) ?
        end
      end

      def rels_from(start_node, options = {})
        start_node.rels_to(self, options)
      end

      def rel_to(node)
        rels_to(node).first
      end


      class << self

        delegate :any_in, :all_in, :where, :find_by, to: :query_builder

        def query_builder
          Neo4j::Rails::Finders::QueryBuilder.new(self)
        end

        def update!(attributes)
          id = attributes[:id]
          raise "No id given" unless id.present?

          resource = self.find(id)
          raise "Resource not found given id:`#{id}'" unless resource

          resource.update_attributes!(attributes)
        end

        def update(attributes)
          id = attributes[:id]
          raise "No id given" unless id.present?

          resource = self.find(id)
          return false unless resource

          resource.update_attributes(attributes)
        end

      end


    end
  end
end