module Neo4j
  module Rails
    module Attributes

      def write_attr_in_transaction(*args)
        self.class.transaction { write_attribute(*args) }
      end

      alias_method :write_attribute_in_transaction, :write_attr_in_transaction

    end
  end
end