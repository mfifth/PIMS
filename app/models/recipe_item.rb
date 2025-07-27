class RecipeItem < ApplicationRecord
  include UnitConversion

  belongs_to :recipe
  belongs_to :product

  def unit_options
    self.class.unit_options
  end

  # Calculate the maximum possible quantity of this recipe item that can be made
  # based on available inventory at the given location
  def max_possible_quantity(location)
    return 0 unless location && product

    # Get all inventory items for this product at the given location
    inventory_items = location.inventory_items.where(product: product)
    
    return 0 if inventory_items.empty?

    # Calculate total available quantity in the recipe's required unit
    total_available = inventory_items.sum do |item|
      begin
        # Convert from inventory_item unit_type to recipe_item unit
        if item.unit_type == unit
          # Same units - use quantity as is
          item.quantity
        elsif UnitConversion.convertible_units?(item.unit_type, unit)
          # Convert the inventory item's quantity to the recipe item's unit
          UnitConversion.convert_quantity(item.quantity, item.unit_type, unit)
        else
          # Units are not convertible - return 0 for this item
          Rails.logger.warn "Non-convertible units: #{item.unit_type} to #{unit} for product #{product.name}"
          0
        end
      rescue => e
        Rails.logger.error "Unit conversion error: #{e.message} - From: #{item.unit_type} To: #{unit}"
        0
      end
    end

    # Return the maximum possible quantity (total available divided by required quantity per recipe)
    return 0 if quantity <= 0
    
    max_possible = (total_available / quantity).floor
    
    # Debug logging
    Rails.logger.debug "RecipeItem #{id} (#{product.name}): total_available=#{total_available}, required_quantity=#{quantity}, unit=#{unit}, max_possible=#{max_possible}"
    
    max_possible
  end

  # Find the earliest expiration date for this recipe item at the given location
  def earliest_expiration(location)
    return nil unless location && product&.perishable?

    # Get all inventory items for this product at the given location
    inventory_items = location.inventory_items
                              .joins(:batch)
                              .where(product: product)
                              .where.not(batches: { expiration_date: nil })
                              .order('batches.expiration_date ASC')

    # Return the earliest expiration date
    inventory_items.first&.expiration_date
  end

  # Get compatible unit options based on the product's default unit type
  def compatible_unit_options
    return {} unless product
    
    # Get the product's default unit type from inventory items
    default_unit = product.inventory_items.first&.unit_type || 'units'
    
    # Return compatible units for the default unit type as a hash for JavaScript
    unit_options = UnitConversion.compatible_unit_options(default_unit)
    unit_options.each_with_object({}) do |option, hash|
      hash[option[:label]] = option[:value]
    end
  end

  # Validate that the selected unit is compatible with the product's inventory units
  def unit_compatible?
    return true unless product
    
    # Get all unit types used in inventory for this product
    inventory_units = product.inventory_items.distinct.pluck(:unit_type)
    
    # Check if recipe unit is compatible with any inventory unit
    inventory_units.any? do |inventory_unit|
      inventory_unit == unit || UnitConversion.convertible_units?(inventory_unit, unit)
    end
  end

  # Get the most common unit type used in inventory for this product
  def suggested_unit
    return 'units' unless product
    
    # Get the most common unit type from inventory items
    product.inventory_items
           .group(:unit_type)
           .order('COUNT(*) DESC')
           .pluck(:unit_type)
           .first || 'units'
  end
end