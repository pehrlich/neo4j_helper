module Neo4j
  module HasN

    class DeclRelationshipDsl
      def inspect
        type = has_one? ? 'has_one' : 'has_n'
        out = "#{self.class.name}  #{target_class} #{self.dir}"

        if self.incoming?
           out << "to #{method_id} from #{relationship_name}"
          "DeclRelationshipDsl: Post has_one incoming to better_post from worse_post"
        else
          out << "from #{method_id} to uhh.."
          "DeclRelationshipDsl: Post has_one incoming from better_post to uhh.."
        end

      end
    end
  end
end