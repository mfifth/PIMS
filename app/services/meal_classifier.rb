class MealClassifier
  FOOD_KEYWORDS = [
    "food", "meal", "entree", "main", "appetizer", "starter", "side", "dessert",
    "dish", "snack", "lunch", "dinner", "breakfast", "combo", "special", "bowl", "box", "plate"
  ].freeze

  NON_MEAL_KEYWORDS = [
    "frozen", "prepackaged", "ready-to-eat", "instant", "microwave", "convenience",
    "meal kit", "can", "bottle", "pack", "six-pack", "carton", "jar", "box", "bag", "pouch",
    "wrapper", "sealed", "shelf-stable", "container", "tub", "packet", "bulk", "multi-pack",
    "soda", "juice", "water", "wine", "beer", "snack", "chips", "crackers", "cereal",
    "candy", "bars", "granola", "nuts", "spice", "seasoning", "sauce", "dressing", "condiment"
  ].freeze

  COMMON_MEAL_NAMES = [
    "burger", "pizza", "sandwich", "pasta", "salad", "cheeseburger", "wings", "fish", "rice",
    "hotdog", "sushi", "taco", "wrap", "noodles", "soup", "nachos", "fries", "steak", "chicken",
    "panini", "gyro", "quesadilla", "burrito", "falafel", "curry", "bento", "omelet", "grill",
    "kabob", "roast", "sub", "hoagie", "lasagna", "meatballs"
  ].freeze

  MEAL_CATEGORIES = [
    "Meals", "Entrees", "Main Courses", "Appetizers", "Dishes", "Courses",
    "Sides", "Desserts", "Specials", "Combos", "Breakfasts", "Dinners", "Lunches"
  ].freeze

  attr_reader :debug_info

  def initialize(item, category_name = nil, debug: false)
    @item = item
    @item_data = item.item_data
    @name = @item_data.name.to_s.downcase
    @description = @item_data.description.to_s.downcase
    @category_name = category_name.to_s.downcase
    @debug = debug
    @debug_info = []
  end

  def meal?
    score = meal_score
    log("Final meal score: #{score}")
    score >= 2
  end

  def meal_score
    score = 0

    if non_meal_keyword_present?
      score -= 3
      log("Matched NON_MEAL keyword => -3")
    end

    if common_meal_name_present?
      score += 2
      log("Matched COMMON_MEAL name => +2")
    end

    if meal_category?
      score += 1
      log("Matched MEAL category => +1")
    end

    if food_keyword_present?
      score += 1
      log("Matched FOOD keyword => +1")
    end

    score
  end

  private

  def meal_category?
    return false if @category_name.empty?
    MEAL_CATEGORIES.any? do |cat|
      match = @category_name.include?(cat.downcase)
      log("Category '#{@category_name}' matched '#{cat}'") if match
      match
    end
  end

  def non_meal_keyword_present?
    NON_MEAL_KEYWORDS.any? do |word|
      match = @name.include?(word) || @description.include?(word)
      log("Non-meal keyword '#{word}' matched") if match
      match
    end
  end

  def food_keyword_present?
    FOOD_KEYWORDS.any? do |word|
      match = @name.include?(word) || @description.include?(word)
      log("Food keyword '#{word}' matched") if match
      match
    end
  end

  def common_meal_name_present?
    COMMON_MEAL_NAMES.any? do |food|
      match = @name.include?(food) || @description.include?(food)
      log("Common meal name '#{food}' matched") if match
      match
    end
  end

  def log(message)
    @debug_info << message if @debug
  end
end
