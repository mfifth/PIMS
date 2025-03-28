# Create some suppliers
supplier_1 = Supplier.create(name: 'Old Mcdonalds Farm')
supplier_2 = Supplier.create(name: 'Joshua Tree')

# Create some sample products
product_1 = Product.create(name: 'Milk - 1 Gallon', sku: 'MILK-1GAL', supplier: supplier_1)
product_2 = Product.create(name: 'Cereal Box', sku: 'CEREAL-BOX', supplier: supplier_1)
product_3 = Product.create(name: 'Orange Juice - 1 Liter', sku: 'OJ-1L', supplier: supplier_2)

# Create some sample locations
location_1 = Location.create(name: 'Main Warehouse', address: '123 Warehouse St.')
location_2 = Location.create(name: 'Secondary Storage', address: '456 Secondary St.')

# Ensure the locations were created successfully
if location_1.persisted? && location_2.persisted?
  # Set the product capacities for each location
  LocationProductCapacity.create(location: location_1, product: product_1, capacity: 100, used_capacity: 0)
  LocationProductCapacity.create(location: location_1, product: product_2, capacity: 200, used_capacity: 0)
  LocationProductCapacity.create(location: location_1, product: product_3, capacity: 150, used_capacity: 0)

  LocationProductCapacity.create(location: location_2, product: product_1, capacity: 50, used_capacity: 0)
  LocationProductCapacity.create(location: location_2, product: product_2, capacity: 100, used_capacity: 0)
  LocationProductCapacity.create(location: location_2, product: product_3, capacity: 75, used_capacity: 0)

  # Add some inventory items for testing
  InventoryItem.create(inventory: location_1.inventory, product: product_1, quantity: 50)
  InventoryItem.create(inventory: location_1.inventory, product: product_2, quantity: 100)
  InventoryItem.create(inventory: location_1.inventory, product: product_3, quantity: 75)

  InventoryItem.create(inventory: location_2.inventory, product: product_1, quantity: 25)
  InventoryItem.create(inventory: location_2.inventory, product: product_2, quantity: 50)
  InventoryItem.create(inventory: location_2.inventory, product: product_3, quantity: 40)

  # Add additional inventory items to test available capacity functionality
  InventoryItem.create(inventory: location_1.inventory, product: product_1, quantity: 30)
  InventoryItem.create(inventory: location_2.inventory, product: product_2, quantity: 60)
else
  puts "Error creating locations. Please check the seed data."
end
