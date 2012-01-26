module Neo4j
  module TypeConverters
    class SerializeConverter
      # serializes to sting
      class << self

        def convert?(type)
          type == :serialize
        end

        def to_java(value)
          return nil unless value
          #JSON.generate(value).to_s # pukes on hashie::mash
          value.to_json
        end

        def to_ruby(value)
          return nil unless value
          JSON.parse(value.to_s)
        end
      end

    end
    converters = nil # reload converters
  end
end
