module Neo4j
  module Rails
    module Relationships
      class AllRelsDsl

        def all
          self.to_a
        end

      end
    end
  end
end