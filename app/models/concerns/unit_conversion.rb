module UnitConversion
  extend ActiveSupport::Concern

  VALID_UNITS = %w[
    grams ounces pounds kilograms liters gallons fluid_oz milliliters units
  ].freeze

  CONVERSION_RATES = {
    'grams' => { 'grams' => 1, 'kilograms' => 0.001, 'ounces' => 1.0 / 28.3495, 'pounds' => 1.0 / 453.592 },
    'kilograms' => { 'grams' => 1000, 'kilograms' => 1, 'ounces' => 35.274, 'pounds' => 2.20462 },
    'ounces' => { 'grams' => 28.3495, 'kilograms' => 0.0283495, 'ounces' => 1, 'pounds' => 1.0 / 16 },
    'pounds' => { 'grams' => 453.592, 'kilograms' => 0.453592, 'ounces' => 16, 'pounds' => 1 },
    'liters' => { 'liters' => 1, 'gallons' => 1.0 / 3.78541, 'fluid_oz' => 33.814, 'milliliters' => 1000 },
    'gallons' => { 'liters' => 3.78541, 'gallons' => 1, 'fluid_oz' => 128, 'milliliters' => 3785.41 },
    'fluid_oz' => { 'liters' => 0.0295735, 'gallons' => 1.0 / 128, 'fluid_oz' => 1, 'milliliters' => 29.5735 },
    'milliliters' => { 'liters' => 0.001, 'gallons' => 0.000264172, 'fluid_oz' => 0.033814, 'milliliters' => 1 },
    'units' => { 'units' => 1 }
  }.freeze

  class << self
    def unit_compatibility_map
      {
        'units' => ['units'],
        'kilograms' => ['grams', 'kilograms'],
        'grams' => ['grams', 'ounces', 'pounds'],
        'ounces' => ['grams', 'ounces', 'pounds'],
        'pounds' => ['grams', 'ounces', 'pounds'],
        'liters' => ['liters', 'fluid_oz', 'milliliters'],
        'fluid_oz' => ['liters', 'fluid_oz', 'milliliters'],
        'gallons' => ['liters', 'gallons', 'fluid_oz', 'milliliters'],
        'milliliters' => ['liters', 'gallons', 'fluid_oz', 'milliliters']
      }
    end

    def compatible_unit_options(base_unit)
      units = unit_compatibility_map[base_unit] || [base_unit]
      units.map { |u| { value: u, label: u.humanize } }
    end

    def unit_options
      VALID_UNITS.map do |u|
        display_name = case u
                       when 'fluid_oz' then 'Fluid Oz'
                       when 'milliliters' then 'Milliliters'
                       else u.humanize
                       end
        { value: u, label: display_name }
      end
    end

    def convertible_units?(from_unit, to_unit)
      return true if from_unit == to_unit

      # Check if we have a conversion rate defined for this unit pair
      return true if CONVERSION_RATES.dig(from_unit, to_unit)

      # Fallback to category-based conversion (for backward compatibility)
      (metric_weight_units?(from_unit) && metric_weight_units?(to_unit)) ||
        (imperial_weight_units?(from_unit) && imperial_weight_units?(to_unit)) ||
        (volume_units?(from_unit) && volume_units?(to_unit)) ||
        (from_unit == 'units' && to_unit == 'units')
    end

    def conversion_rate(from_unit, to_unit)
      CONVERSION_RATES.dig(from_unit, to_unit) || 1
    end

    def convert_quantity(amount, from_unit, to_unit)
      return amount if from_unit == to_unit
      return 0 unless convertible_units?(from_unit, to_unit)

      amount * conversion_rate(from_unit, to_unit)
    end

    def round_for_unit(quantity, unit)
      case unit
      when 'grams', 'kilograms', 'liters', 'milliliters' then quantity.round(4)
      when 'ounces', 'pounds', 'gallons', 'fluid_oz' then quantity.round(2)
      else quantity.round
      end
    end

    private

    def metric_weight_units?(unit)
      %w[grams kilograms].include?(unit)
    end

    def imperial_weight_units?(unit)
      %w[ounces pounds].include?(unit)
    end

    def volume_units?(unit)
      %w[liters gallons fluid_oz milliliters].include?(unit)
    end
  end
end
