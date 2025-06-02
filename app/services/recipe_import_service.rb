class RecipeImportService
  require 'csv'

  def initialize(user:, file_contents:)
    @user = user
    @account = user.account
    @file_contents = file_contents
    @recipes = {}
    @product_cache = @account.products.index_by(&:sku)
  end

  def import
    utf8_contents = @file_contents.force_encoding('UTF-8')

    CSV.parse(utf8_contents, headers: true) do |row|
      recipe_name = row['recipe_name'].to_s.strip
      sku         = row['sku'].to_s.strip
      quantity    = row['quantity'].to_f
      unit_type   = row['unit_type'].to_s.strip.presence || "unit"
      price       = row['price'].to_f

      next if recipe_name.blank? || sku.blank? || quantity <= 0

      product = @product_cache[sku]
      next unless product

      recipe = (@recipes[recipe_name] ||= find_or_create_recipe(recipe_name, price))
      create_or_update_recipe_item(recipe, product, quantity, unit_type)
    end
  end

  private

  def find_or_create_recipe(name, price)
    Recipe.find_or_create_by!(account: @account, name: name) do |r|
      r.uid = SecureRandom.hex(10)
      r.price = price
    end
  end

  def create_or_update_recipe_item(recipe, product, quantity, unit)
    RecipeItem.find_or_create_by!(recipe: recipe, product: product) do |item|
      item.quantity = quantity
      item.unit = unit
    end
  end
end
