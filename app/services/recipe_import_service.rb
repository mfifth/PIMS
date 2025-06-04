class RecipeImportService
  require 'csv'

  VALID_UNITS = %w[grams ounces pounds kilograms liters gallons fluid_oz milliliters units].freeze

  def initialize(user:, file_contents:)
    @user = user
    @account = user.account
    @file_contents = file_contents
    @recipes = {}
    @product_cache = @account.products.index_by(&:sku)
    @success_count = 0
    @failure_rows = []
  end

  def import
    utf8_contents = @file_contents.force_encoding('UTF-8')

    CSV.parse(utf8_contents, headers: true).with_index(2) do |row, line_num|
      begin
        recipe_name = row['recipe_name'].to_s.strip
        sku         = row['sku'].to_s.strip
        quantity    = row['quantity'].to_f
        unit_type   = row['unit_type'].to_s.strip.downcase
        price       = row['price'].to_f

        raise "Missing recipe_name, sku, quantity, or unit_type" if recipe_name.blank? || sku.blank? || quantity <= 0 || unit_type.blank?
        raise "Invalid unit type: #{unit_type}" unless VALID_UNITS.include?(unit_type)

        product = @product_cache[sku]
        raise "SKU not found: #{sku}" unless product

        recipe = (@recipes[recipe_name] ||= find_or_create_recipe(recipe_name, price))
        create_or_update_recipe_item(recipe, product, quantity, unit_type)

        @success_count += 1
      rescue => e
        log_import_failure(line_num, e.message, row.to_h)
      end
    end

    {
      success: @success_count,
      failed: @failure_rows.size,
      errors: @failure_rows
    }
  end

  private

  def log_import_failure(line_num, error, row_data)
    message = "CSV Recipe Import Error on line #{line_num}: #{error}. Data: #{row_data.to_json}"

    Notification.create!(
      account_id: @account.id,
      message: message,
      notification_type: "Recipe Import Error"
    )

    @failure_rows << {
      line: line_num,
      error: error,
      data: row_data
    }
  end


  def find_or_create_recipe(name, price)
    Recipe.find_or_create_by!(account: @account, name: name) do |r|
      r.uid = SecureRandom.hex(10)
      r.price = price
    end
  end

  def create_or_update_recipe_item(recipe, product, quantity, unit)
    item = RecipeItem.find_or_initialize_by(recipe: recipe, product: product)
    item.quantity = quantity
    item.unit = unit
    item.save!
  end
end
