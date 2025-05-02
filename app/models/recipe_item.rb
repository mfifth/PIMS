class RecipeItem < ApplicationRecord
  belongs_to :recipe
  belongs_to :product

  VALID_UNITS = %w[grams ounces pounds liters gallons fluid_oz milliliters units].freeze
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
      'gallons' => 1.0/3.78541,
      'fluid_oz' => 33.814,
      'ml' => 1000
    },
    'gallons' => {
      'liters' => 3.78541,
      'gallons' => 1,
      'fluid_oz' => 128,
      'ml' => 3785.41
    },
    'fluid_oz' => {
      'liters' => 0.0295735,
      'gallons' => 1.0/128,
      'fluid_oz' => 1,
      'ml' => 29.5735
    },
    'milliliters' => {
      'liters' => 0.001,
      'gallons' => 0.000264172,
      'fluid_oz' => 0.033814,
      'ml' => 1
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
      'units' => ['units'],
      'grams' => ['grams', 'ounces', 'pounds'],
      'ounces' => ['grams', 'ounces', 'pounds'],
      'pounds' => ['grams', 'ounces', 'pounds'],
      'liters' => ['liters', 'gallons', 'fluid_oz', 'ml'],
      'gallons' => ['liters', 'gallons', 'fluid_oz', 'ml'],
      'fluid_oz' => ['liters', 'gallons', 'fluid_oz', 'ml'],
      'milliliters' => ['liters', 'gallons', 'fluid_oz', 'ml']
    }
  end

  def self.unit_options
    VALID_UNITS.map do |u| 
      display_name = case u
                    when 'fluid_oz' then 'Fluid Oz'
                    when 'ml' then 'Milliliters'
                    else u.humanize
                    end
      [display_name, u]
    end
  end

  def converted_quantity(target_unit = product.unit_type)
    return quantity if unit == target_unit || !convertible_units?(unit, target_unit)

    base_quantity = quantity * conversion_rate(unit, target_unit)
    round_for_unit(base_quantity, target_unit)
  end

  def compatible_unit_options
    # Get all unique unit types from inventory items for this product
    inventory_units = product.inventory_items.pluck(:unit_type).compact.uniq
    
    # If no inventory items, use product's unit_type
    available_units = inventory_units.any? ? inventory_units : [product.unit_type || 'units']
    
    # Filter to only valid units and convert to display format
    available_units.select { |u| VALID_UNITS.include?(u) }
                  .map do |unit|
                    display_name = case unit
                                  when 'fluid_oz' then 'Fluid Oz'
                                  when 'ml' then 'Milliliters'
                                  else unit.humanize
                                  end
                    [display_name, unit]
                  end
  end

  def convertible_units?(from_unit, to_unit)
    return true if from_unit == to_unit
    return false if from_unit == 'units' || to_unit == 'units'
    
    # Check if units are in the same category
    (weight_units?(from_unit) && weight_units?(to_unit)) ||
    (volume_units?(from_unit) && volume_units?(to_unit))
  end

  private

  def weight_units?(unit)
    %w[grams ounces pounds].include?(unit)
  end

  def volume_units?(unit)
    %w[liters gallons fluid_oz milliliters].include?(unit)
  end

  def conversion_rate(from_unit, to_unit)
    CONVERSION_RATES.dig(from_unit, to_unit) || 1
  end

  def round_for_unit(quantity, unit)
    case unit
    when 'grams', 'liters', 'milliliters' then quantity.round(4)
    when 'ounces', 'pounds', 'gallons', 'fluid_oz' then quantity.round(2)
    else quantity.round
    end
  end
end