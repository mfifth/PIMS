class Types::DateType < GraphQL::Schema::Scalar
  description "A Date in the format YYYY-MM-DD"

  def self.coerce_input(value, context)
    Date.parse(value)
  rescue ArgumentError
    nil # or raise an error if needed
  end

  def self.coerce_result(value, context)
    value.to_s # convert Date to string
  end
end