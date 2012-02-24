module Neo4j
  module Rails
    class Model

      # Channel.rels2(to: location)
      # Channel.rels2(:located, to: location)

      def rels2(type, options = {})
        # type is optinal parameter
        if type.is_a? Hash
          options = type
          type = nil
        end

        # todo: allow both directions?
        if end_node = options[:to]
          rels = type ? self.rels(type) : self.rels
          rels.to_other(end_node)
        elsif start_node = options[:from]
          rels = type ? start_node.rels(type) : start_node.rels
          rels.to_other(self)
        else
          self.rels(type)
        end
      end

      def ensure_relation(type, options = {}, props = {})
        # options: to and from
        if (rels = rels2(type, options)).present?
          # if found, update attributes
          rel = rels.first
          #rel.attributes = props
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

        if old_rel = self.rels2(rel_type).first
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
          rels.each &:delete
        end
      end


      def relate(type, options = {}, props = {})
        if end_node = options[:to]
          start_node = self
        elsif start_node = options[:from]
          end_node = self
        else
          raise ':to or :from is required'
        end
        Neo4j::Rails::Relationship.create(type, start_node, end_node, props)
      end

      # todo: deprecate in favor of rels2
      def rels_to(end_node, options = {})
        if type = options[:type]
          rels(type).to_other(end_node)
        else
          self.rels.to_other(end_node)
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