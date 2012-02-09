# neo4j_helper Rails

This is an add-on library to https://github.com/andreasronge/neo4j

I was just using mongoid, and it was great because you could throw anything at it and have it work.  This is an
attempt to bring rails neo4j to the same accomplishment.  

Read the source, its educational.


    gem install neo4j_helper


## Usage

Methods are automatically added to Neo4j::Rails::Model.  This means once you install the gem, you can't get away from them.  If this causes issues, let me know, and maybe we can implement a mixin instead.


### Automatic JSON serialization

    # user.rb
    property :facebook_credentials, :type => :serialize

Todo: allow indexing and searching on serialized info, like mongoid.  (see: [group post](https://groups.google.com/d/msg/neo4jrb/KWxKBMbCc9E/E2XKIhzyvucJ)


### Automatic object creation

Notices a passed-in hash to a relationship, and makes the right node.  You can pass a block if it returns a model instance.

    # user.rb
    has_one(:location).to(Location)
    accepts_hash_for :location do |attributes|
        Location.new attributes
    end

In fact, the above is done automatically with no block, so this is just the same effect:

    # user.rb
    has_one(:location).to(Location)
    accepts_hash_for :location

### Tuples

Tuples are a useful tool for packaging the relationships going to a node with the node itself.
The goal of the tuple is to allow extremely simple to/from json with rel data and node data combined.

For example:

    Tuple.new(some_location, user_rels).to_json
    => {
        :id => '1', # this is the location node id
        :name => 'Argyle, NY',
        :rel_status => 'hidden' # argyle is hidden for this user
    }

The second goal is to allow easy manipulation and understanding of multiple relationships between two nodes.

For example, keeping many relationships as node history:

    mega_rel = MyRelHistory.new(user_rels)
    Tuple.new(some_location, mega_rel).to_json
    => {
        :id => '1', # this is the location node id
        :name => 'Argyle, NY',
        :rel_average_time_active => '11 days'
    }

In this case, `rel_average_time_active` is produced by the MyRelHistory class.  A default mega rel is provided,
which wraps a sole relationship:

    class MegaRel
      def initialize(rels)
        @rels = rels
      end

      attr_accessor :rels

      def method_missing(symbol, *args)
        @rels.first.send(symbol, args)
      end
    end


Tuples can be used as such:

    # return an array of tuples between the user and their goal
    User.first.goals.tuples

    # update the tuple to the node w/ the given id
    User.first.goals.update_tuple_attributes(params[:goal])

### Misc

 - when #last is not available, it gives a nicer method saying only # first is available.
 - #find_by as synonym to #find

TODO: niceties to try and bring the syntax as close as possible to mongoid;

 - .limit(), .page(), and .sort(),
 - allowing the :unique flag to be passed to indexes (like mongoid),
 - making the difference between the Lucene query and neo4j traversal more evident, useful, or hidden
 - looking for some syntactic sugar so that its not necessary to do a wildcard query returning a lucene search in order to run a sort.
 - command to automatically add missing indexes
 - make it so that when invalid parameters get passed to rels, it pukes, rather than returning a Class
 - make Class objects more debuggable


#### todo: Allow cool rel queries:

    # before:
    self.expand { |n| n._rels.find_all {|r| r[:latest] == true && r._end_node[:_classname] == :goal } }.to_a
    # ideal query:
    self.rels.in_java.where({:latest => true}).end_node(:classname => :goal)
    # or maybe
    rel_scope :goal_history, in_ruby.where({:latest => true}).targeting(:goal)


## Contributing


Once you've made your great commits

1. Fork
1. Pull # > git clone git://whatever
1. Push # > git push
1. Pull request # github's GUI
1. \# That's it!



## Contributors

Peter Ehrlich [@ehrlicp](http://www.twitter.com/ehrlicp)
<br/>
(This rdoc written with Mou, a sweet markdown editor from [@chenluois](http://twitter.com/chenluois))
