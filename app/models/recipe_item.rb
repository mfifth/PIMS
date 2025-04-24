class RecipeItem < ApplicationRecord
  belongs_to :recipe
  belongs_to :product

  VALID_UNITS = %w[grams ounces pounds liters gallons units].freeze
  CONVERSION_RATES = {
    'grams' => {
      'grams' => 1,
      'ounces' => 1.0/28.3495,
      'pounds' => 1.0/453.592
    },
    'ounces' => {
      'grams' => 28.3495,
      'ounces' => 1,
      'pounds' => 1.0/16
    },
    'pounds' => {
      'grams' => 453.592,
      'ounces' => 16,
      'pounds' => 1
    },
    'liters' => {
      'liters' => 1,
      'gallons' => 1.0/3.78541
    },
    'gallons' => {
      'liters' => 3.78541,
      'gallons' => 1
    },
    'units' => {
      'units' => 1
    }
  }.freeze

  validates :quantity, numericality: { greater_than: 0 }
  validates :unit, presence: true, inclusion: { in: VALID_UNITS }
  validates :product_id, presence: true

  def self.unit_compatibility_map
    {
      "grams" => %w[grams ounces pounds],
      "ounces" => %w[grams ounces pounds],
      "pounds" => %w[grams ounces pounds],
      "liters" => %w[liters gallons],
      "gallons" => %w[liters gallons],
      "units" => %w[units]
    }
  end

  def self.unit_options
    VALID_UNITS.map { |u| [u.humanize, u] }
  end

  def converted_quantity(target_unit = product.unit_type)
    return quantity if unit == target_unit || !convertible_units?(unit, target_unit)

    base_quantity = quantity * conversion_rate(unit, target_unit)
    round_for_unit(base_quantity, target_unit)
  end

  def compatible_unit_options
    return self.class.unit_options unless product&.unit_type
  
    self.class::VALID_UNITS.select do |unit|
      convertible_units?(unit, product.unit_type)
    end.map { |unit| [unit.humanize, unit] }
  end

  private

  def convertible_units?(from_unit, to_unit)
    return true if from_unit == to_unit
    return false if from_unit == 'units' || to_unit == 'units'
    
    # Check if units are in the same category
    (weight_units?(from_unit) && weight_units?(to_unit)) ||
    (volume_units?(from_unit) && volume_units?(to_unit))
  end

  def weight_units?(unit)
    %w[grams ounces pounds].include?(unit)
  end

  def volume_units?(unit)
    %w[liters gallons].include?(unit)
  end

  def conversion_rate(from_unit, to_unit)
    CONVERSION_RATES.dig(from_unit, to_unit) || 1
  end

  def round_for_unit(quantity, unit)
    # More precision for smaller units
    case unit
    when 'grams', 'liters' then quantity.round(4)
    when 'ounces', 'pounds', 'gallons' then quantity.round(2)
    else quantity.round
    end
  end
end