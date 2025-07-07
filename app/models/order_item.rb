class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :item, polymorphic: true
  belongs_to :location

  def base_unit
    item.try(:unit_type) || 'units'
  end

  def total_price
    if inventory_item?
      item_unit = item.unit_type
      converted_quantity = UnitConversion.convert(quantity, from: unit, to: item_unit)
      UnitConversion.rounded(converted_quantity * price, item_unit)
    else
      (quantity * price).round(2)
    end
  end

  def sold_unit
    self.unit || base_unit
  end

  def converted_unit_price
    return price unless inventory_item?

    if sold_unit != base_unit
      UnitConversion.convert(1.0, from: sold_unit, to: base_unit) * item.price
    else
      item.price
    end
  rescue
    item.price
  end

  def converted_quantity
    return quantity unless inventory_item?

    if sold_unit != base_unit
      UnitConversion.convert(quantity.to_f, from: sold_unit, to: base_unit)
    else
      quantity.to_f
    end
  rescue
    quantity.to_f
  end

  def subtotal
    (converted_unit_price * quantity.to_f).round(2)
  end

  def inventory_item?
    item_type == "InventoryItem" && item.present?
  end
end
