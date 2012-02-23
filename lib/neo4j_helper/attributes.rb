module Neo4j
  module Rails
    module Attributes

      def write_attr_in_transaction(*args)
        self.class.transaction { write_attribute(*args) }
      end

      alias_method :write_attribute_in_transaction, :write_attr_in_transaction

      def props_with_symbolized_keys
        props_without_symbolized_keys.symbolize_keys
      end

      def attributes_with_symbolized_keys
        attributes_without_symbolized_keys.symbolize_keys
      end

      alias_method_chain :props, :symbolized_keys
      alias_method_chain :attributes, :symbolized_keys


    end
  end
end