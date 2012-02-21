module Neo4j
  module Rails
    class Model

      def ensure_relation(type, options = {}, props = {})
        # options: to and from
        if end_node = options[:to]
          rels = rels_to(end_node, type: type)
        elsif start_node = options[:from]
          rels = rels_from(start_node, type: type)
        end

        if rels.present?
          rel = rels.first
          #rel.attributes = props
          rel.update_attributes props
          rel
        else
          relate(type, options, props)
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