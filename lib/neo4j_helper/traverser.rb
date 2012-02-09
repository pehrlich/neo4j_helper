module Neo4j
  module Rels
    class Traverser
      # todo: can this class combined with like allrelsdsl?

      def all
        self.to_a
      end

    end
  end
end