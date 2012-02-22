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