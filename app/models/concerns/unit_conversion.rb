module UnitConversion
  VALID_UNITS = %w[grams ounces pounds kilograms liters gallons fluid_oz milliliters units].freeze

  CONVERSION_RATES = {
    # weight
    'grams' => { 'grams' => 1, 'kilograms' => 0.001, 'ounces' => 1 / 28.3495, 'pounds' => 1 / 453.592 },
    'ounces' => { 'grams' => 28.3495, 'ounces' => 1, 'pounds' => 1.0 / 16 },
    'pounds' => { 'grams' => 453.592, 'ounces' => 16, 'pounds' => 1 },
    'kilograms' => { 'grams' => 1000, 'kilograms' => 1 },

    # volume
    'liters' => { 'liters' => 1, 'milliliters' => 1000, 'fluid_oz' => 33.814, 'gallons' => 1 / 3.78541 },
    'milliliters' => { 'liters' => 0.001, 'milliliters' => 1, 'fluid_oz' => 0.033814 },
    'fluid_oz' => { 'liters' => 0.0295735, 'fluid_oz' => 1 },
    'gallons' => { 'liters' => 3.78541, 'fluid_oz' => 128, 'milliliters' => 3785.41 },

    # whole
    'units' => { 'units' => 1 }
  }.freeze

  def self.valid_units
    VALID_UNITS
  end

  def self.compatible?(unit_a, unit_b)
    return true if unit_a == unit_b
    (CONVERSION_RATES[unit_a]&.key?(unit_b)) || (CONVERSION_RATES[unit_b]&.key?(unit_a)) || false
  end

  def self.compatible_units_for(base_unit)
    CONVERSION_RATES[base_unit]&.keys || [base_unit]
  end

  def self.convert(amount, from:, to:)
    return amount if from == to
    rate = CONVERSION_RATES.dig(from, to)
    raise ArgumentError, "Incompatible units: #{from} to #{to}" unless rate
    amount * rate
  end

  def self.rounded(amount, unit)
    case unit
    when 'grams', 'milliliters' then amount.round(1)
    when 'fluid_oz', 'ounces' then amount.round(2)
    else amount.round(3)
    end
  end
end
