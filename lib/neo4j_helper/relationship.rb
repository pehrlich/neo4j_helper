module Neo4j
  module Rails

    class Relationship

      def inspect
        # todo: colors
        #NoMethodError: undefined method `neo_id' for nil:NilClass
        #from /Users/peter/Rails/zendestiny/vendor/gems/neo4j_helper/lib/neo4j_helper/relationship.rb:8:in `inspect'
        "Rel #{self.neo_id} (#{start_node.inspect})-[:#{rel_type.to_s}]->(#{end_node.inspect})"
        # this doesn't make any sense? How can rel be nil AND a Relationship?
        # but this doesn't fix it:
        #"Rel #{self.try(:neo_id)} (#{start_node.inspect})-[:#{rel_type.to_s}]->(#{end_node.inspect})"
      end

      # todo: why is it that when I run this manually, I get the proper output?
      # what?
      #jruby-1.6.6 :004 > p.rels.map { |r|  r.rel_type.to_s + ': ' + r.start_node.inspect + ' --> ' + r.end_node.inspect  }
      # => ["Post#worse_post: Post 18 --> Post 19", "Post#worse_post: Post 18 --> Post 19", "_all: #<#<Class:0x49c99fc>:0x4f51ce2e> --> Post 19"]

    end
  end
end