module Neo4jHelpers

  extend ActiveSupport::Concern

  included do
    alias_method :properties, :attributes
  end

  module InstanceMethods

  end

  module ClassMethods

    def find_by(options)
      self.find(options)
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
