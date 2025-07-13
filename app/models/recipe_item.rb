class RecipeItem < ApplicationRecord
  include UnitConversion

  belongs_to :recipe
  belongs_to :product

  def unit_options
    self.class.unit_options
  end
end