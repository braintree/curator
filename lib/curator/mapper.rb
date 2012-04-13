module Curator
  class Mapper
    def initialize(field_name, options)
      @field_name = field_name
      @serialize_function = options[:serialize]
      @deserialize_function = options[:deserialize]
    end

    def deserialize(attributes)
      _map(attributes, @deserialize_function)
    end

    def serialize(attributes)
      _map(attributes, @serialize_function)
    end

    def _map(attributes, mapping_function)
      current_value = attributes[@field_name]
      if current_value && mapping_function
        mapped_value = mapping_function.call(current_value)
        attributes.merge(@field_name => mapped_value)
      else
        attributes
      end
    end
  end
end
