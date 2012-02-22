module Neo4j
  module Rails

    class Relationship

      def inspect
        # todo: colors
        "Rel #{self.neo_id} (#{start_node.inspect})-[:#{rel_type.to_s}]->(#{end_node.inspect})"
      end

      # todo: why is it that when I run this manually, I get the proper output?
      # what?
      #jruby-1.6.6 :004 > p.rels.map { |r|  r.rel_type.to_s + ': ' + r.start_node.inspect + ' --> ' + r.end_node.inspect  }
      # => ["Post#worse_post: Post 18 --> Post 19", "Post#worse_post: Post 18 --> Post 19", "_all: #<#<Class:0x49c99fc>:0x4f51ce2e> --> Post 19"]

    end
  end
end