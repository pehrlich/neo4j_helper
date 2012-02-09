module Neo4j
  module Rails
    module Relationships

      class Storage

        def each_tuple(dir, &block)
          # we could here allow filtering of nodes and rels
          # but unless we set similar filtering db-level, there's little point

          # some no DRY fuss to cache from db
          rels = relationships(dir) # this only gets unpersisted
          if @node.persisted?
            # cache everything we can becasue how it works is confusing
            cache_persisted_nodes_and_relationships(dir) if @persisted_related_nodes[dir].nil?
            cache_relationships(dir) if @persisted_relationships[dir].nil?

            rels.concat @persisted_relationships[dir].select { |rel| rel.exist? }
          end

          # rels now holds ruby objects
          # {Node#123 => [Rel#1, Rel#2, Rel#3]}

          # todo: understand and abstract
          remote_node = (dir == :outgoing ? :end_node : :start_node)

          rels.group_by{|r| r.send(remote_node)}.map do |remote_node, rels|

            block.call Tuple.new(remote_node, rels)
          end
        end

      end

    end
  end
end