module Neo4j
  module Rails
    class Model
      class << self

        # Allows custom behavior when a hash is passed in to a relationship setter
        # Default behavior is retained when a non-hash is given
        #
        # has_one(:location)
        # accepts_hash_for :location
        #
        # Will run Location.new with the passed in :location hash.
        #
        # You can also give it a block to return a node:
        #
        # accepts_hash_for :location do |properties|
        #   Location.find_or_create_by(name: properties[:name])
        # end
        #
        def accepts_hash_for(prop, *block)
          # todo: handle persistence?
          # for working with this method, see these neo4j examples:
          # def _add_relationship(rel_type, node)
          # def update_nested_attributes
          # def accepts_nested_attributes_for

          rel = self._decl_rels[prop.to_sym]
          raise "No relationship declared with has_n or has_one with type #{prop}" unless rel

          if rel.has_one?
            setter = :"#{prop}="
            original_setter = :"#{prop}_without_accepting_hash="

            define_method :"#{prop}_with_accepting_hash=" do |value|
              # only call custom method if not already a model or nil.  This way we catch hash, mash, etc.
              if !value.respond_to?(:properties) && !value.nil?
                # not sure what would be to happen if a block were somehow to be given to the setter method
                value = if block_given?
                          yield value
                        else
                          # todo: allow find_or_create
                          ((id = value[:id]) && rel.target_class.find(id)) || rel.target_class.new(value)
                        end
              end

              send(original_setter, value)
            end

            alias_method_chain setter, :accepting_hash
          end

        else
          # todo: has_n
        end


      end

    end
  end
end