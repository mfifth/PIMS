# db/seeds.rb

require 'faker'
require 'securerandom'

# Create an Account
account = Account.create!(
  stripe_customer_id: SecureRandom.hex(8),
  created_at: Time.current,
  updated_at: Time.current
)

subscription = Subscription.create(account_id: account.id)

# Create a User
user = User.create!(
  name: "Alex Morgan",
  email_address: "alex@example.com",
  password: "password123",
  password_digest: BCrypt::Password.create("password123"),
  account: account,
  phone: "555-123-4567",
  email_notification: true,
  admin: true,
  confirmed_at: Time.current
)

# Create Locations
location1 = Location.create!(
  name: "Downtown Bistro",
  address: "123 Main Street",
  city: "Metropolis",
  state: "NY",
  zip_code: "10001",
  country: "USA",
  account: account,
  location_uid: SecureRandom.hex(5)
)

# Create Products
products = [
  { name: "Fresh Mozzarella", sku: "MOZZ123", perishable: true, unit_type: "pounds" },
  { name: "Roma Tomatoes", sku: "TOM456", perishable: true, unit_type: "pounds" },
  { name: "Basil Leaves", sku: "BASIL789", perishable: true, unit_type: "bunch" },
  { name: "All-Purpose Flour", sku: "FLOUR321", perishable: false, unit_type: "pounds" },
  { name: "Chicken Breast", sku: "CHICK654", perishable: true, unit_type: "pounds" },
  { name: "Romaine Lettuce", sku: "LETTUCE987", perishable: true, unit_type: "units" },
  { name: "Whole Wheat Tortilla", sku: "TORT159", perishable: false, unit_type: "units" },
  { name: "Cucumber", sku: "CUKE753", perishable: true, unit_type: "units" },
  { name: "Feta Cheese", sku: "FETA852", perishable: true, unit_type: "pounds" }
].map do |attrs|
  Product.create!(
    attrs.merge(
      description: Faker::Food.description,
      price: rand(1.0..15.0).round(2),
      account: account
    )
  )
end

# Create Batches
products.each do |product|
  Batch.create!(
    batch_number: SecureRandom.hex(4),
    manufactured_date: 2.weeks.ago,
    expiration_date: product.perishable ? 1.month.from_now : nil,
    account: account,
    notification_days_before_expiration: product.perishable ? 7 : 0
  )
end

# Create Inventory Items at Locations
products.each do |product|
  InventoryItem.create!(
    product: product,
    location: location1,
    quantity: rand(10..100),
    daily_usage: rand(1..5),
    low_threshold: 5
  )
end

# Create Recipes
recipes = [
  { name: "Margherita Pizza", ingredients: [
    { product_name: "Fresh Mozzarella", quantity: 0.5, unit: "pounds" },
    { product_name: "Roma Tomatoes", quantity: 1.0, unit: "pounds" },
    { product_name: "Basil Leaves", quantity: 3, unit: "grams" },
    { product_name: "All-Purpose Flour", quantity: 1.5, unit: "pounds" }
  ]},
  { name: "Chicken Caesar Salad", ingredients: [
    { product_name: "Chicken Breast", quantity: 0.5, unit: "lbs" },
    { product_name: "Romaine Lettuce", quantity: 1.0, unit: "head" },
    { product_name: "Feta Cheese", quantity: 0.25, unit: "lbs" }
  ]},
  { name: "Veggie Wrap", ingredients: [
    { product_name: "Whole Wheat Tortilla", quantity: 1.0, unit: "units" },
    { product_name: "Cucumber", quantity: 1.0, unit: "each" },
    { product_name: "Roma Tomatoes", quantity: 0.5, unit: "lbs" },
    { product_name: "Feta Cheese", quantity: 0.25, unit: "lbs" }
  ]}
]

recipes.each do |recipe_attrs|
  recipe = Recipe.create!(
    uid: SecureRandom.uuid,
    name: recipe_attrs[:name],
    account: account
  )

  recipe_attrs[:ingredients].each do |ingredient|
    product = products.find { |p| p.name == ingredient[:product_name] }
    if product
      RecipeItem.create!(
        recipe: recipe,
        product: product,
        quantity: ingredient[:quantity],
        unit: ingredient[:unit]
      )
    end
  end
end

puts "✅ Seeded: 1 account, 1 user, 1 locations, #{products.count} products, #{recipes.count} recipes!"
