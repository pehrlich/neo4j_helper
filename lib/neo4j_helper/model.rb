module Neo4j
  module Rails
    class Model

      def self.update!(attributes)
        id = attributes[:id]
        raise "No id given" unless id.present?

        resource = self.find(id)
        raise "Resource not found given id:`#{id}'" unless resource

        resource.update_attributes!(attributes)
      end

      def self.update(attributes)
        id = attributes[:id]
        raise "No id given" unless id.present?

        resource = self.find(id)
        return false unless resource

        resource.update_attributes(attributes)
      end


      def rels_to(node)
        self.rels.to_other(node)
      end

      def rel_to(node)
        rels_to(node).first
      end

    end
  end
end