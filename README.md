# neo4j_helper Rails

This is an add-on library to https://github.com/andreasronge/neo4j

I was just using mongoid, and it was great because you could throw anything at it and have it work.  This is an
attempt to bring rails neo4j to the same accomplishment.  

Read the source, its educational.


    # This gem is alpha.  The following doesn't work yet:
    # for now, run a git pull and install in vendor/gems
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

    t = Tuple.new(some_location, current_user.rels_to(some_location))
    t.rels # the rels outgoing from user
    t.end_node # the user


Note: Currently this relies on acts_as_api, that code should be extracted to an addon to the acts_as_api_gme

Todo: The second goal is to allow easy manipulation and understanding of multiple relationships between two nodes.


Tuples can be used as such:

    # return an array of tuples between the user and their goal
    User.first.goals.tuples

    # update the tuple to the node w/ the given id
    User.first.goals.update_tuple_attributes(params[:goal])


### Query Builder

this comes with a new experimental query builder, for example:

    Post.tuples(:from => current_user).order(:updated_at).limit(3).all

    Post.tuples(:to => current_user).fulltext(:name => {:all => name.split}).limit(limit).page(page)


### Syntactical sugar
 - lots of undocumented things (todo: document)
 - allow #new as well as #build when setting up relationships
 - created the model method: write_attr_in_transaction, which saves you from needing a blocks.



### Misc

 - when #last is not available, it gives a nicer method saying only # first is available.
 - #find_by as synonym to #find

TODO: niceties to try and bring the syntax as close as possible to mongoid;

 - figure out if both fulltext and exact indices can be made on a single field
 - allow .as when setting up has_n and has_one
 - allowing the :unique flag to be passed to indexes (like mongoid),
 - making the difference between the Lucene query and neo4j traversal more evident, useful, or hidden
 - command to automatically add missing indexes
 - make it so that when invalid parameters get passed to rels, it pukes, rather than returning a Class
 - make Class objects more debuggable


 nodes and rels are held cached before persistence:

  - can we do anything to make this more evident?
  - i.e., inspection either saying post #, or post # cached rel

  => #<Post:0x128d1417 @_relationships={:"Post#posts"=>#<Neo4j::Rails::Relationships::Storage:0x1adb8a22 @rel_class=Neo4j::Rails::Relationship, @target_class=Neo4j::Rails::Model, @incoming_rels=[#<Neo4j::Rails::Relationship:0x21ed22af @start_node=Goal 5, @properties={}, @end_node=#<Post:0x128d1417 ...>, @properties_before_type_cast={}, @type="Post#posts">], @node=#<Post:0x128d1417 ...>, @rel_type=:"Post#posts", @persisted_related_nodes={}, @outgoing_rels=[], @persisted_relationships={}, @persisted_node_to_relationships={}>, :"User#notified_users"=>#<Neo4j::Rails::Relationships::Storage:0x57d437c @rel_class=Notification, @target_class=User, @incoming_rels=[], @node=#<Post:0x128d1417 ...>, @rel_type=:"User#notified_users", @persisted_related_nodes={}, @outgoing_rels=[Notification ], @persisted_relationships={}, @persisted_node_to_relationships={}>}, @changed_attributes={"body"=>nil}, @properties={"body"=>"123"}, @properties_before_type_cast={:body=>"123"}>
 jruby-1.6.6 :021 > p.save
  => true
 jruby-1.6.6 :022 > u.notifications.first
  => #<Post:0x26cffd3e @_relationships={}, @_java_node=#<#<Class:0x63a80928>:0x592d9d9a>, @properties={}, @properties_before_type_cast={}>


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
1. Pull
1. Push
1. Pull request



## Contributors

Peter Ehrlich [@ehrlicp](http://www.twitter.com/ehrlicp)
<br/>
(This rdoc written with Mou, a sweet markdown editor from [@chenluois](http://twitter.com/chenluois))
