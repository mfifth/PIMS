class RecipesController < ApplicationController
  before_action :set_recipe, only: [:edit, :update, :destroy]

  def new
    @recipe = Current.account.recipes.new
  end

  def edit
  end
  
  def index
    @recipes = Current.account.recipes.includes(recipe_items: :product).order(created_at: :desc)
    
    if params[:search].present?
      search_term = "%#{params[:search].downcase}%"
      @recipes = @recipes.where(
        "LOWER(name) LIKE :search OR LOWER(uid) LIKE :search", 
        search: search_term
      )
    end
  end

  def create
    @recipe = Current.account.recipes.new(recipe_params)
    @recipe.uid = SecureRandom.uuid

    respond_to do |format|
      if @recipe.save
        format.turbo_stream
      else
        render :new, status: :unprocessable_entity
      end
    end
  end

  def product_search
    query = params[:query].to_s.strip
    selected_ids = params[:selected_ids] || []
  
    @products = if query.present?
      base_scope = Current.account.products.where.not(id: selected_ids).where(perishable: true)
      
      if ActiveRecord::Base.connection.adapter_name.downcase.include?("sqlite")
        base_scope.where("LOWER(name) LIKE ?", "%#{query.downcase}%").limit(5)
      else
        base_scope.where("name ILIKE ?", "%#{query}%").limit(10)
      end
    else
      []
    end
  
    respond_to do |format|
      format.turbo_stream {
        render turbo_stream: turbo_stream.update(
          "product_search_results",
          partial: "recipes/product_search_results",
          locals: { products: @products }
        )
      }
    end
  end

  def update
    if @recipe.update(recipe_params)
      redirect_to recipes_path, notice: "Recipe was successfully updated."
    else
      render :edit
    end
  end

  def destroy
    @recipe.destroy
  
    respond_to do |format|
      format.html { redirect_to recipes_path, notice: "Recipe deleted successfully." }
      format.turbo_stream
    end
  end
  
  private

  def set_recipe
    @recipe = Current.account.recipes.find(params[:id])
  end

  def recipe_params
    params.require(:recipe).permit(:name, 
    recipe_items_attributes: [:id, :product_id, :quantity, :unit, :_destroy])
  end
end
