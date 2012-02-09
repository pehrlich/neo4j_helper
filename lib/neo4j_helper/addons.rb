module Neo4jHelpers

  module Addons
    extend ActiveSupport::Concern

    included do
      alias_method :properties, :attributes
    end

    module InstanceMethods

    end

    module ClassMethods

      # alias_method :prop, :property
      # NameError: undefined method `property' for module `Neo4jHelpers::Addons::ClassMethods'
      def prop
        property
      end

      def find_by(options)
        self.find(options)
      end

      def any_in(options)
        #Vehicle.find(:wheels => 2).or(:wheels => 4).not(:name => 'old bike')
        # if you pass a symbol to find, it gives back goal 47

        if options.is_a? Array
          field = :id
          values = options
        elsif options.is_a? Hash
          field = options.keys.first
          values = options.values.first
        else
          field = :id
          values = [options]
        end


        return nil unless field.present? && values.present?

        #p "any in #{field} #{values}"
        results = values.map do |value|
          #p "finding #{field} #{value} - #{field.class} #{value.class}"
          self.find(field => value)
        end
        results.compact

        #query = self.find(field => values.shift)
        #
        #values.each do |value|
        #  logger.warn "adding to query: or #{value}"
        #  query.or(field => value)
        #end
        #
        #query
      end

    end
  end

end


=begin
 todo:

So far will mainly include niceties to try and bring the syntax as close as possible to mongoid;
 - .limit(), .page(), and .sort(),
 - allowing the :unique flag to be passed to indexes (like mongoid),
 - making the difference between the Lucene query and neo4j traversal more evident, useful, or hidden
 - looking for some syntactic sugar so that its not necessary to do a wildcard query returning a lucene search in order to run a sort.
 - command to automatically add missing indexes
 - figure out "title: long" vs :title => "long"

 - way to obtain write lock without quitting and restarting server?

=end
