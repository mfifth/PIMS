class RecipeItem < ApplicationRecord
  belongs_to :recipe
  belongs_to :product

  VALID_UNITS = %w[grams ounces pounds kilograms liters gallons fluid_oz milliliters units].freeze
  CONVERSION_RATES = {
    'grams' => {
      'grams' => 1,
      'kilograms' => 0.001,
      'ounces' => 1.0 / 28.3495,
      'pounds' => 1.0 / 453.592
    },
    'kilograms' => {
      'grams' => 1000,
      'kilograms' => 1
    },
    'ounces' => {
      'grams' => 28.3495,
      'kilograms' => 0.0283495,
      'ounces' => 1,
      'pounds' => 1.0 / 16
    },
    'pounds' => {
      'grams' => 453.592,
      'kilograms' => 0.453592,
      'ounces' => 16,
      'pounds' => 1
    },
    'liters' => {
      'liters' => 1,
      'gallons' => 1.0 / 3.78541,
      'fluid_oz' => 33.814,
      'milliliters' => 1000
    },
    'gallons' => {
      'liters' => 3.78541,
      'gallons' => 1,
      'fluid_oz' => 128,
      'milliliters' => 3785.41
    },
    'fluid_oz' => {
      'liters' => 0.0295735,
      'gallons' => 1.0 / 128,
      'fluid_oz' => 1,
      'milliliters' => 29.5735
    },
    'milliliters' => {
      'liters' => 0.001,
      'gallons' => 0.000264172,
      'fluid_oz' => 0.033814,
      'milliliters' => 1
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

  def converted_quantity(inventory_quantity, inventory_unit)
    return inventory_quantity if unit == inventory_unit
    return 0 unless convertible_units?(inventory_unit)

    (inventory_quantity * conversion_rate(inventory_unit, unit)).round(4)
  end

  def max_possible_quantity(location)
    inventory_items = product.inventory_items.where(location: location)
    return 0 if inventory_items.empty? || quantity <= 0

    total = inventory_items.sum do |item|
      if convertible_units?(item.unit_type)
        converted_quantity(item.quantity, item.unit_type)
      else
        0
      end
    end

    (total / quantity).floor
  end

  def earliest_expiration(location)
    return nil unless product.perishable?
    
    # Check if there's any inventory for this product at the location
    has_inventory = product.inventory_items.where(location: location).exists?
    return nil unless has_inventory
    
    product.batch&.expiration_date
  end

  def compatible_unit_options
    # Get the product's base unit (first check inventory, then fall back to product.unit_type)
    base_unit = if product.inventory_items.any?
                  product.inventory_items.first.unit_type
                else
                  product.unit_type || 'units'
                end
  
    # Get all compatible units from the compatibility map
    compatible_units = self.class.unit_compatibility_map[base_unit] || [base_unit]
  
    # Format for select dropdown
    compatible_units.map do |unit|
      display_name = case unit
                    when 'fluid_oz' then 'Fluid Oz'
                    when 'ml' then 'Milliliters'
                    else unit.humanize
                    end
      [display_name, unit]
    end
  end

  def convertible_units?(from_unit)
    (metric_weight_units?(unit) && metric_weight_units?(from_unit)) ||
    (imperial_weight_units?(unit) && imperial_weight_units?(from_unit)) ||
    (volume_units?(unit) && volume_units?(from_unit)) ||
    (unit == 'units' && from_unit == 'units')
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

  def conversion_rate(from_unit, to_unit)
    CONVERSION_RATES.dig(from_unit, to_unit) || 1
  end

  def round_for_unit(quantity, unit)
    case unit
    when 'grams', 'kilograms', 'liters', 'milliliters' then quantity.round(4)
    when 'ounces', 'pounds', 'gallons', 'fluid_oz' then quantity.round(2)
    else quantity.round
    end
  end
end