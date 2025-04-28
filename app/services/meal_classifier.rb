class MealClassifier
    FOOD_KEYWORDS = [
      "food", "meal", "entree", "main", "appetizer", "starter", "side", "dessert",
      "dish", "snack", "lunch", "dinner", "breakfast", "combo", "special", "bowl", "box", "plate"
    ].freeze
  
    NON_MEAL_KEYWORDS = [
      "boxed", "wrapped", "frozen", "prepackaged", "ready-to-eat", "instant",
      "microwave", "convenience", "meal kit", "can", "bottle", "pack", "six-pack", "carton"
    ].freeze
  
    COMMON_MEAL_NAMES = [
      "burger", "pizza", "sandwich", "pasta", "steak", "salad", "cheeseburger",
      "hotdog", "sushi", "taco", "wrap", "wings", "noodles", "soup", "nachos", "fries"
    ].freeze
  
    MEAL_CATEGORIES = [
      "Meals", "Entrees", "Main Courses", "Appetizers", "Dishes", "Courses",
      "Sides", "Desserts", "Specials", "Combos", "Breakfasts", "Dinners", "Lunches"
    ].freeze
  
    def initialize(item, category_name = nil)
      @item = item
      @item_data = item.item_data
      @name = @item_data.name.to_s.downcase
      @description = @item_data.description.to_s.downcase
      @category_name = category_name.to_s.downcase
    end
  
    def meal?
      return false if non_meal_keyword_present?
      return true if common_meal_name_present?
  
      meal_category? || food_keyword_present?
    end
  
    private
  
    def meal_category?
      return false if @category_name.empty?
      MEAL_CATEGORIES.any? { |cat| @category_name.include?(cat.downcase) }
    end
  
    def non_meal_keyword_present?
      NON_MEAL_KEYWORDS.any? { |word| @name.include?(word) || @description.include?(word) }
    end
  
    def food_keyword_present?
      FOOD_KEYWORDS.any? { |word| @name.include?(word) || @description.include?(word) }
    end
  
    def common_meal_name_present?
      COMMON_MEAL_NAMES.any? { |food| @name.include?(food) || @description.include?(food) }
    end
  end
  