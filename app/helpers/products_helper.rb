module ProductsHelper
  def show_price(product)
    return unless product.price.positive?
    "#{I18n.t('products.price')}: #{product.price} |"
  end

  def show_batch_info(product)
    mfg = product&.batch&.manufactured_date || I18n.t('products.na')
    exp = product&.batch&.expiration_date || I18n.t('products.na')
    "#{I18n.t('products.mfg')}: #{mfg} - #{I18n.t('products.exp')}: #{exp}"
  end

  def convert_units(quantity, unit_type)
    case unit_type
    when 'pounds'
      quantity * 16 # Convert to ounces if the unit is pounds
    when 'ounces'
      quantity # Keep it in ounces
    when 'grams'
      quantity * 0.03527396 # Convert grams to ounces
    when 'liters'
      quantity * 33.814 # Convert liters to ounces (1 liter = 33.814 oz)
    when 'gallons'
      quantity * 128 # Convert gallons to ounces (1 gallon = 128 oz)
    else
      quantity # If no conversion needed, return the quantity as is
    end
  end

  # For displaying unit conversions in a readable format
  def display_converted_quantity(quantity, unit_type)
    case unit_type
    when 'pounds'
      "#{quantity} lbs"
    when 'ounces'
      "#{quantity} oz"
    when 'grams'
      "#{quantity} g"
    when 'liters'
      "#{quantity} l"
    when 'gallons'
      "#{quantity} gal"
    else
      "#{quantity} #{unit_type}"
    end
  end
end
