class RecipeItemsController < ApplicationController
    def unit_options
      product = Current.account.products.find(params[:product_id])
      recipe_item = RecipeItem.new(product: product)
      render json: recipe_item.compatible_unit_options
    end
end