# neo4j_helper

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

### Misc


TODO: niceties to try and bring the syntax as close as possible to mongoid;

 - .limit(), .page(), and .sort(),
 - allowing the :unique flag to be passed to indexes (like mongoid),
 - making the difference between the Lucene query and neo4j traversal more evident, useful, or hidden
 - looking for some syntactic sugar so that its not necessary to do a wildcard query returning a lucene search in order to run a sort.
 - command to automatically add missing indexes
 - whatever comes next



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
