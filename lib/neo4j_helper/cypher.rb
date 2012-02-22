module Neo4j

  # one option would be to make methods for every hash item here (method_missing)
  # allowing     results.map &:post # convert to post array
  def self.cypher(string = nil, options = {})
    cypher = Neo4j::Cypher.new(string, options)
    # call results immediately if string given
    string.present? ? cypher.results : cypher
  end
  
  class Cypher

    def initialize(string = nil, options={})
      # todo: options such as as: :java or as: :ruby
      @string = string

      @start = nil
      @match = nil
      @ret = nil
    end

    def results
      query = @string || [@start, @match, @ret].join(' ')
      rows = Neo4j.query query

      # note: there are many cases where we won't need wrapping, such as for determining rel_type
      # but for now, this is premature optimization

      # paths cannot be wrapped
      rows.map do |row|
        out = {} # move to a real hash!
        row.each do |key, value|
          #row.delete(key) # Java::JavaLang::UnsupportedOperationException: remove
          #key[key.to_sym] Java::JavaLang::UnsupportedOperationException: 	from java.util.AbstractMap.put(AbstractMap.java:186)
          out[key.to_sym] = value.respond_to?(:wrapper) ? value.wrapper : value
        end
        out
      end

    end


    def start(string)
      @start = "START #{string}"
      #"START self = node(#{self.neo_id})"
    end

    def match(string)
      @match = "MATCH #{string}"
    end

    # ret(user: {rel: :rel})
    # takes a data structure to format the results in to?
    # ret(Tuple)
    # calls Tuple.new(*args)
    def ret(string)
      @ret = "RETURN #{string}"
    end

  end
end