class RecipesController < ApplicationController
  before_action :set_recipe, only: [:edit, :update, :destroy]
  before_action :require_admin!

  def new
    @recipe = Current.account.recipes.new
  end

  def edit
  end
  
  def index
    @recipes = Current.account.recipes.includes(recipe_items: :product, products: :inventory_items).order(created_at: :desc)
    
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
  
    respond_to do |format|
      if @recipe.save
        format.turbo_stream
      else
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "main",
            partial: "form",
            locals: { recipe: @recipe, form_title: "New Recipe", submit_text: "Create Recipe", show_delete: false }
          )
        end
      end
    end
  end

  def product_search
    query = params[:query].to_s.strip
    selected_ids = Array(params[:selected_ids])
  
    if query.blank?
      @products = []
    else
      base_scope = Current.account.products
                            .left_joins(:inventory_items)
                            .where.not(id: selected_ids)
                            .where(perishable: true)
                            .select("products.*, inventory_items.unit_type AS inventory_unit_type")
                            .distinct
  
      Rails.logger.debug "ProductSearch SQL: #{base_scope.to_sql}"
  
      @products = base_scope
                    .where("LOWER(products.name) LIKE LOWER(?)", "%#{query}%")
                    .limit(5)
    end
  
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "product_search_results",
          partial:     "recipes/product_search_results",
          locals:      { products: @products }
        )
      end
    end
  end  

  def update
    if @recipe.update(recipe_params)
      redirect_to recipes_path, notice: t('recipe_updated')
    else
      render :edit
    end
  end

  def destroy
    @recipe.destroy
  
    respond_to do |format|
      format.html { redirect_to recipes_path, notice: t('recipe_deleted') }
      format.turbo_stream
    end
  end
  
  private

  def set_recipe
    @recipe = Current.account.recipes.find(params[:id])
  end

  def recipe_params
    params.require(:recipe).permit(:name, :uid, :price,
    recipe_items_attributes: [:id, :product_id, :quantity, :unit, :_destroy])
  end
end
