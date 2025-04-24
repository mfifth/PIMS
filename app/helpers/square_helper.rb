module SquareHelper
	private
	
	def process_order(account, data)
	  order_id = data["id"]
	  order_items = data["line_items"]
  
	  order_items.each do |item|
		catalog_object_id = item["catalog_object_id"]
		quantity_sold = item["quantity"].to_i
  
		recipe = account.recipes.find_by(uid: catalog_object_id)
		
		if recipe
		  process_recipe_order(account, recipe, quantity_sold, data["location_id"])
		else
		  product = account.products.find_by(sku: catalog_object_id)
		  next unless product
  
		  location = account.locations.find_by(location_uid: data["location_id"])
		  next unless location
  
		  update_inventory_item(product, location, -quantity_sold)
		end
	  end
  
	  Rails.logger.info("Processed order #{order_id} for account #{account.id}")
	end
  
	def process_recipe_order(account, recipe, quantity_sold, location_uid)
	  location = account.locations.find_by(location_uid: location_uid)
	  return unless location
  
	  recipe.recipe_items.each do |recipe_item|
		product = recipe_item.product
		next unless product&.unit_type
  
		# Convert the recipe item quantity to match the product's unit type
		converted_quantity = if recipe_item.unit == product.unit_type || 
							  !convertible_units?(recipe_item.unit, product.unit_type)
							  recipe_item.quantity
							else
							  recipe_item.quantity * conversion_rate(recipe_item.unit, product.unit_type)
							end
  
		quantity_to_deduct = converted_quantity * quantity_sold
		update_inventory_item(product, location, -quantity_to_deduct)
	  end
	end
  
	def update_inventory_item(product, location, quantity_change)
	  inventory_item = InventoryItem.find_or_initialize_by(product: product, location: location)
	  inventory_item.quantity += quantity_change
	  inventory_item.save!
	end
  
	# Unit conversion helper methods from RecipeItem
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
	  {
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
	  }.dig(from_unit, to_unit) || 1
	end
  end