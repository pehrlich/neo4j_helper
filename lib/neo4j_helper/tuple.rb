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

        def as_api_response(api_template, context = nil)
          # todo: use context as a way to replace rels

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
    end
  end
end