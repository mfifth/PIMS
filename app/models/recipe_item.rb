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
      'kilograms' => 1,
      'ounces' => 35.274,
      'pounds' => 2.20462
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

  def max_possible_quantity(location)
    inventory_items = product.inventory_items.where(location: location)
    return 0 if inventory_items.empty? || quantity <= 0

    total_available = inventory_items.sum do |item|
      if can_convert?(item.unit_type)
        converted = convert_quantity(item.quantity, item.unit_type)
        round_for_unit(converted, unit)
      else
        0
      end
    end

    (total_available / quantity).floor
  end

  def cost_per_recipe(location)
    inventory_items = product.inventory_items.where(location: location)
    return product.price.to_f * quantity if inventory_items.empty?
  
    price_per_recipe_unit = inventory_items.first.price
    converted_quantity = quantity
  
    if unit != inventory_items.first.unit_type
      conversion_rate = CONVERSION_RATES.dig(unit, inventory_items.first.unit_type)
      if conversion_rate
        converted_quantity = quantity * conversion_rate
      else
        return product.price.to_f * quantity
      end
    end
  
    price_per_recipe_unit * converted_quantity
  end

  def earliest_expiration(location)
    return nil unless product.perishable?
    
    product.inventory_items
           .where(location: location)
           .joins(:batch)
           .where.not(batches: { expiration_date: nil })
           .minimum('batches.expiration_date')
  end

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

    converted = inventory_quantity * conversion_rate(inventory_unit, unit)
    round_for_unit(converted, unit)
  end

  def compatible_unit_options
    base_unit = if product.inventory_items.any?
                  product.inventory_items.first.unit_type
                else
                  product.unit_type || 'units'
                end
  
    compatible_units = self.class.unit_compatibility_map[base_unit] || [base_unit]
  
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

  def can_convert?(from_unit)
    return true if unit == from_unit
    CONVERSION_RATES.dig(from_unit, unit).present?
  end

  def convert_quantity(amount, from_unit)
    return amount if unit == from_unit
    
    conversion_rate = CONVERSION_RATES.dig(from_unit, unit)
    return 0 unless conversion_rate

    amount * conversion_rate
  end
end