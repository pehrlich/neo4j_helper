class Cypher

  def start
    "START self = node(#{self.neo_id})"
  end

  def match(string)
    "MATCH #{string}"
  end

  # ret(user: {rel: :rel})
  # takes a data structure to format the results in to?
  # ret(Tuple)
  # calls Tuple.new(*args)
  def ret(*args)
    "RETURN "
  end

end