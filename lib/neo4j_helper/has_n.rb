module Neo4j
  module HasN
    module ClassMethods
      def has_many(*args)
        has_n(*args)
      end
    end
  end
end