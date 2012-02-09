module Neo4j
  module Rails
    module Relationships

      class Tuple
        # todo: to_s/inspect?
        # todo: store _megarel_type in dsl declaration
        # note: an alternative api would accept two nodes, and automatically get the rels between
        # perhaps not doing so allows the most flexibility

        #extend ActsAsApi::Base
        #acts_as_api

        #def initialize(end_node, rels_or_mega_rel)
        def initialize(end_node, rels)
          #def initialize(origin_node, remote_node, decl_rel = nil) # todo: accept rel class
          # alternate input: attributes, mega_rel

          #raise "no node given" unless node
          #raise "no rels given" unless rels
          #@node = node

          #raise 'Unimplemented: specified decl_rel' unless decl_rel == nil

          @end_node = end_node
          @rels = rels


          #@origin_node = origin_node
          #@remote_node = remote_node
          #@rel = MegaRel.new(origin_node.rels_to(remote_node).all)
          #p ",egarel:"
          #p @rel

          #@rel = if rels_or_mega_rel.respond_to? :rels
          #         rels_or_mega_rel
          #       else
          #         MegaRel.new(rels)
          #       end
          self
        end

        attr_accessor :end_node, :rels

        def as_api_response(api_template)

          node_hash, rels_hash = [@end_node, @rels].map do |item|
            item.respond_to?(:as_api_response) ? item.as_api_response(api_template) : item
          end

          # for now, limited to one rel
          node_hash[:rel] = rels_hash.first
          node_hash
        end

        def to_json
          #{
          #    :rels => rels
          #}
          [@end_node, @rels]
          #@end_node
        end


        #attr_accessor :origin_node, :remote_node#, :rel

        #def rel
        #  # todo: this needs to create a new rel if none existing
        #  @rel
        #end
        #
        #def rels
        #  # rel is a mega rel made up of many rels
        #  @rel.rels
        #end
        #
        #def node
        #  origin_node
        #end
        #
        #delegate :rels=, :to => :rel

        #def to_hash(options = {})
        #  {
        #      #:node => @node,
        #      :remote_node => @remote_node,
        #      :origin_node => @origin_node,
        #      :rel => self.rels
        #  }
        #end
        #
        #def to_json(*args)
        #  # note, destination of args not final
        #  out = @remote_node.to_json(*args)
        #
        #  self.rel.props.each do |key, val|
        #    out[:"rel_#{key}"] = val
        #  end
        #
        #  out
        #end

        #def save
        #  @remote_node.save
        #  @rel.save # saves the mega rel
        #end
        #
        #def attributes=(attributes)
        #  rel_attrs = {}
        #  # attributes becomes node_attributes
        #  attributes.each do |key, value|
        #    if key.to_s[0..3] == 'rel_'
        #      rel_attrs[key] = attributes.delete(key)
        #    end
        #  end
        #
        #  @remote_node.attributes= attributes
        #  @rel.attributes= rel_attrs
        #end
        #
        #def update_attributes(attributes)
        #  self.attributes= attributes
        #  self.save
        #end
        #
        #class MegaRel
        #  def initialize(rels)
        #    @rels = rels || []
        #  end
        #
        #  attr_accessor :rels
        #
        #  def save
        #    @rels.first.save if @rels && @rels.first
        #  end
        #
        #  def create(attributes = {})
        #    raise 'unimplemented: create w/ decl_dsl'
        #    # could:create non-declared relationship here
        #  end
        #
        #  def attributes=(*args)
        #    # allow creation on nil?
        #    if @rels.first
        #      @rels.first.attributes=(args)
        #    else
        #      self.create(args)
        #    end
        #  end
        #
        #  def method_missing(symbol, *args)
        #    @rels.first.send(symbol, args)
        #  end
        #end

      end

      class NodesDSL
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


