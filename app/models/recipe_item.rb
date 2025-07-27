class RecipeItem < ApplicationRecord
  include UnitConversion

  belongs_to :recipe
  belongs_to :product

  def unit_options
    self.class.unit_options
  end

  def max_possible_quantity(location)
    return 0 unless location && product

    inventory_items = location.inventory_items.where(product: product)
    return 0 if inventory_items.empty?

    target_unit = unit.presence || suggested_unit

    total_available = inventory_items.sum do |item|
      begin
        if item.unit_type == target_unit
          item.quantity
        elsif UnitConversion.convertible_units?(item.unit_type, target_unit)
          UnitConversion.convert_quantity(item.quantity, item.unit_type, target_unit)
        else
          Rails.logger.warn "Non-convertible units: #{item.unit_type} to #{target_unit} for product #{product.name}"
          0
        end
      rescue => e
        Rails.logger.error "Unit conversion error: #{e.message} - From: #{item.unit_type} To: #{target_unit}"
        0
      end
    end

    return 0 if quantity <= 0
    (total_available / quantity).floor
  end

  def earliest_expiration(location)
    return nil unless location && product&.perishable?

    inventory_items = location.inventory_items
                              .joins(:batch)
                              .where(product: product)
                              .where.not(batches: { expiration_date: nil })
                              .order('batches.expiration_date ASC')

    inventory_items.first&.expiration_date
  end

  def compatible_unit_options
    return {} unless product
    
    default_unit = product.inventory_items.first&.unit_type || 'units'
    
    unit_options = UnitConversion.compatible_unit_options(default_unit)
    unit_options.each_with_object({}) do |option, hash|
      hash[option[:label]] = option[:value]
    end
  end

  def unit_compatible?
    return true unless product
    
    inventory_units = product.inventory_items.distinct.pluck(:unit_type)
    
    inventory_units.any? do |inventory_unit|
      inventory_unit == unit || UnitConversion.convertible_units?(inventory_unit, unit)
    end
  end

  def suggested_unit
    return 'units' unless product
    
    product.inventory_items
           .group(:unit_type)
           .order(Arel.sql('COUNT(*) DESC'))
           .pluck(:unit_type)
           .first || 'units'
  end
end