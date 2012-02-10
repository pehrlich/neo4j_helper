module Neo4j
  module Rails
    module Relationships

      class NodesDSL
        # todo: improve inspect method:
        #=> #<Neo4j::Rails::Relationships::NodesDSL:0x5b7d6f73
        # @dir=:outgoing,
        #
        # @storage=#<Neo4j::Rails::Relationships::Storage:0x82015f2
        #  @rel_class=Notification, @target_class=User, @incoming_rels=[],
        #  @node=#<Post:0x17557412
        #   @_relationships={:"User#notified_users"=>#<Neo4j::Rails::Relationships::Storage:0x82015f2 ...>},
        #  @properties={"body"=>"123"}, @properties_before_type_cast={},
        #  @_java_node=#<#<Class:0x32c98179>:0x61bb0cc0>>,
        #
        # @rel_type=:"User#notified_users",
        #  @persisted_related_nodes={},
        #  @outgoing_rels=[],
        #  @persisted_relationships={},
        #  @persisted_node_to_relationships={}>>



        # enumarables don't have last.. :-O
        delegate :first, :to => :all

        # for some reason, this doesn't work:
        def relate(remote_node, attributes = nil)
          # rel = Action.new(User.goals, self, goal)
          # rel.latest = true

          # this method is a misnomer.  Should be new_relationship_to
          #rel = @dsl.create_relationship_to(@node, remote_node)
          rel = @storage.create_relationship_to(remote_node, @dir)

          # contrary to what you might expect, this doesn't remove attributes not set in the hash
          rel.attributes= attributes if attributes

          rel
        end

        def ensure_relation(remote_node, attributes = nil)
          if rel = @storage.to_other(remote_node).first
            rel.attributes= attributes if attributes
            rel
          else
            relate(remote_node, attributes)
          end
        end

        # User.goals.tuples # instead of #all
        # returns unum of tuples
        # we can let tuples take any arguments, and we can return a query builder instead of an enumerable
        def tuples
          @storage.enum_for(:each_tuple, @dir)
        end

        def tuple(origin_node, remote_node_or_id)
          # todo: if Storage had a find method, we could accept node_or_id here.
          # todo: the following taken from other source.  should use persisted? method instead
          # todo: also, need to confirm both need to exist
          #raise "cannot tuple from to to a non-persisted node" unless @node._java_node && remote_node._java_node

          if remote_node_or_id.is_a? Fixnum
            remote_node = self.find_by_id remote_node_or_id
            raise "invalid id, node `#{remote_node_or_id}' not found" unless remote_node
          else
            remote_node = remote_node_or_id
          end

          # not sure why, but @node is not set and origin_node is required
          # can we move this to a more higher up creation?
          # specifically, megarel should be defined class level

          Tuple.new(remote_node, @node.rels.to_other(remote_node))
          #p "creating tuple between"
          #p origin_node
          #p remote_node
          #Tuple.new(@node, remote_node)

          #Tuple.new(origin_node, remote_node)
        end

        def update_tuple_attributes(attributes)
          # how the rel is updated is determined by the megarel class,
          # so we don't need a rel id here.
          # the default class just passes the attributes to the first rel, assuming only one

          raise "no id given" unless id = attributes[:id]

          tuple = @storage.enum_for(:each_tuple, @dir).find { |n| n.id.to_i == id }
          raise "invalid id, tuple `#{id}' not found" unless tuple

          tuple.update_attributes(attributes)
        end

        # this method is unfinished
        # this allows us to pass in hashes with :rel_ attributes
        def create_tuple!(attributes)
          # split the attrs (needs DRYing)
          rel_attrs = {}
          attributes.each do |key, value|
            if key.to_s[0..3] == 'rel_'
              rel_attrs[key] = attributes.delete(key)
            end
          end

          # find or create the one node
          if target_node = @target_class.find(attributes[:id])
            target_node.update_attributes!(attributes)
          else
            target_node = @target_class.create!(attributes)
          end

          self.relate(target_node, rel_attrs)

          # finally, make and return the tuple
          #Tuple.new(@node, target_node)
          #Tuple.new(@node, target_node)

        end

        def new(*args)
          build(*args)
        end


        #
        #def single_tuple
        #  # todo?
        #end
        #
        #def nodes(options)
        #  # sets conditions for returned nodes
        #end
        #
        #def rels
        #  # sets conditions for returned rels
        #end

        #def order_nodes
        #  # sets order method
        #end
        #
        #def order_rels
        #  # sets order method
        #end
        #
        #def limit_rels
        #
        #end
        #
        #def limit_nodes
        #
        #end


      end
    end
  end
end


