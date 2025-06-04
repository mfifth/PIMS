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
    each_csv_row do |row, line_num|
      process_row(row, line_num)
    rescue => e
      record_failure(line_num, e.message, row.to_h)
    end

    notify_failures

    {
      success: @success_count,
      failed: @failure_rows.size,
      errors: @failure_rows
    }
  end

  private

  def each_csv_row
    utf8 = @file_contents.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
    CSV.parse(utf8, headers: true).each_with_index do |row, i|
      yield row, i + 2  # Line number starts at 2 (header is line 1)
    end
  end

  def process_row(row, line_num)
    data = extract_and_validate_row(row)

    product = @product_cache[data[:sku]]
    raise "SKU not found: #{data[:sku]}" unless product

    recipe = @recipes[data[:recipe_name]] ||= find_or_create_recipe(data[:recipe_name], data[:price])
    create_or_update_recipe_item(recipe, product, data[:quantity], data[:unit_type])

    @success_count += 1
  end

  def extract_and_validate_row(row)
    recipe_name = row['recipe_name'].to_s.strip
    sku         = row['sku'].to_s.strip
    quantity    = row['quantity'].to_f
    unit_type   = row['unit_type'].to_s.strip.downcase
    price       = row['price'].to_f

    raise "Missing recipe_name, sku, quantity, or unit_type" if recipe_name.blank? || sku.blank? || quantity <= 0 || unit_type.blank?
    raise "Invalid unit type: #{unit_type}" unless VALID_UNITS.include?(unit_type)

    {
      recipe_name: recipe_name,
      sku: sku,
      quantity: quantity,
      unit_type: unit_type,
      price: price
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

  def record_failure(line_num, error, data)
    @failure_rows << { line: line_num, error: error, data: data }
  end

  def notify_failures
    @failure_rows.each do |failure|
      Notification.create!(
        account_id: @account.id,
        message: "CSV Recipe Import Error on line #{failure[:line]}: #{failure[:error]}. Data: #{failure[:data].to_json}",
        notification_type: "recipe_import_error"
      )
    end
  end
end
