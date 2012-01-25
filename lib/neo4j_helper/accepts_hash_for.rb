module Neo4j
  module Rails
    class Model
      class << self

        # This allows anything to be thrown at a relationship and understood.
        # usage:
        #
        # has_one(:location).to(Location)
        # accepts_hash_for :location
        #
        # Will run Location.new with the passed in :location hash.
        # You can also give it a block which returns a location node:
        #
        # accepts_hash_for :location do |location_attributes|
        #   Location.find_or_create_by(:name => location_attributes[:name])
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

            define_method :"#{prop}_with_accepting_hash=" do |attributes|

              node = if attributes.is_a? rel.target_class
                       attributes
                     elsif attributes.present?
                       # not sure what would be to happen if a block were somehow to be given to the setter method
                       if block_given?
                         yield(attributes)
                       else
                         # todo: allow find_or_create

                         ((id = attributes[:id]) && target_class.find(id)) || target_class.new(attributes)
                       end
                     else
                       nil
                     end

              send(original_setter, node)
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