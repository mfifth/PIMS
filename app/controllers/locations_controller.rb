require 'csv'

class LocationsController < ApplicationController
  before_action :set_location, only: %i[show edit update destroy import_products]
  before_action :verify_file_type, only: [:import_products]
  before_action :require_admin!, only: [:create, :edit, :update, :new, :destroy, :import_products]

  def index
    @recipes = Current.account.recipes.includes(recipe_items: :product)
    @locations = Current.account.locations.includes(:inventory_items)
    
    @locations.each do |loc|
      perishable = loc.inventory_items.joins(:product).where(products: { perishable: true }).count
      non_perishable = loc.inventory_items.joins(:product).where(products: { perishable: false }).count
      
      loc.define_singleton_method(:perishable_count) { perishable }
      loc.define_singleton_method(:non_perishable_count) { non_perishable }
    end
  end

  def show
      @active_filters = {
      perishable: params[:perishable],
      low_stock: params[:low_stock],
      expiring: params[:expiring]
    }

    @inventory_items = @location.inventory_items
                  .includes(:product, :batch, product: :category)
                  .order('products.name ASC')

    if params[:perishable].present?
      @inventory_items = @inventory_items.joins(:product).where(products: { perishable: params[:perishable] })
    end

    if params[:low_stock] == 'true'
      @inventory_items = @inventory_items.where('quantity <= low_threshold')
    end

    if params[:expiring] == 'true'
      @inventory_items = @inventory_items.joins(:batch)
                                        .where("batches.expiration_date BETWEEN ? AND ?", 
                                              Date.current, 
                                              1.week.from_now.to_date)
    end

    respond_to do |format|
      format.html
      format.turbo_stream
      format.csv do
        headers['Content-Disposition'] = "attachment; filename=inventory_#{@location.name.parameterize}_#{Time.current}.csv"
        headers['Content-Type'] ||= 'text/csv'
        render plain: generate_csv(@inventory_items)
      end
    end
  end

  def new
    @location = Location.new
  end

  def create
    @location = Location.new(location_params.merge(account_id: Current.account.id))
    if @location.save
      redirect_to @location, notice: t('notifications.location_created')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    respond_to do |format|
      format.html
      format.turbo_stream
    end 
  end

  def update
    if @location.update(location_params)
      redirect_to @location, notice: t('notifications.location_updated')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @location.destroy
    redirect_to locations_path, notice: t('notifications.location_deleted')
  end

  def inventory
  end

  def update_inventory
    inventory_item = InventoryItem.find_by(location_id: params[:location_id], product_id: params[:product_id])
    inventory_item.update(
      quantity: params[:quantity],
      batch_id: params[:batch_id]
    )
    
    redirect_back fallback_location: '/', notice: t('notifications.inventory_updated')
  end

  def inventory_data
    location = Location.find(params[:location_id])
    inventory_items = location.inventory_items
                       .includes(:product, :batch)
  
    render json: {
      products: inventory_items.map do |item|
        {
          id: item.product_id,
          name: item.product.name,
          quantity: item.quantity,
          category_id: item.product.category_id,
          batch_id: item.batch_id,
          unit_type: item.unit_type.titleize
        }
      end
    }
  end

  def categories
    @location = Location.find(params[:id])
    @page = params[:page] || 1

    @categories = @location.inventory_items
      .joins(product: :category)
      .group('categories.id', 'categories.name')
      .select(
        'categories.id as category_id',
        'categories.name as category_name',
        'SUM(quantity) as total_quantity',
        'SUM(quantity * products.price) as total_value'
      )
      .order(Arel.sql('SUM(quantity * products.price) DESC'))
      .page(@page)
      .per(@per_page)
    
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @location }
    end
  end

  def import_products
    return unless params[:file].present?
  
    file_contents = params[:file].read
  
    if Rails.env.development?
      CsvImporter.new(
        user: Current.user,
        location: @location,
        file_contents: file_contents
      ).import
  
      redirect_to @location
    else
      CsvImportJob.perform_later(file_contents, Current.user.id, @location.id)
      redirect_to @location, notice: t('locations.csv_import_notice')
    end
  end  

  def sample_csv
    expiring_soon      = (Time.current + 5.days).strftime("%Y-%m-%d")
    medium_expiration  = (Time.current + 30.days).strftime("%Y-%m-%d")
    long_expiration    = (Time.current + 1.year).strftime("%Y-%m-%d")
    manufactured_today = Time.current.strftime("%Y-%m-%d")
    manufactured_last_week = (Time.current - 7.days).strftime("%Y-%m-%d")
  
    sample_data = <<~CSV
      sku*,name*,unit_type*,price,quantity*,category,perishable*,batch_number*,expiration_date*,low_stock_alert,notification_days_before_expiration,manufactured_date
      BAK123,All-Purpose Flour,pounds,3.49,250,Baking,true,FLR001,#{long_expiration},50,10,#{manufactured_today}
      BVR456,Orange Juice,gallons,4.99,120,Beverages,true,OJU023,#{medium_expiration},30,7,#{manufactured_last_week}
      CLS789,Cotton T-Shirt,units,12.99,500,Clothing,false,,,,20,,2025-03-15
      ELC321,Wireless Mouse,units,24.95,80,Electronics,false,,,,10,,2025-02-28
      FRT654,Fresh Strawberries,ounces,5.50,180,Fruit,true,STRW789,#{expiring_soon},40,5,#{manufactured_today}
      HHS987,Liquid Hand Soap,liters,2.99,300,Health,false,,,,25,,2025-01-10
      MTD258,Ground Beef,pounds,6.99,75,Meat,true,GBF456,#{medium_expiration},20,3,#{manufactured_last_week}
      SEA369,Canned Tuna,units,1.29,400,Seafood,true,TUN789,#{(Time.current + 2.years).strftime("%Y-%m-%d")},60,15,2025-02-01
      VEG147,Organic Carrots,pounds,2.29,200,Vegetables,true,CRT321,#{medium_expiration},30,5,#{manufactured_today}
      SNK753,Granola Bars,units,0.99,10,Snacks,false,,,,5,3,2024-12-15
      LTH111,Low Stock Sugar,grams,1.99,60,Baking,true,SGR123,#{long_expiration},100,7,#{manufactured_today}
      EXP999,Expiring Cheese,pounds,4.49,50,Dairy,true,CHS999,#{expiring_soon},20,5,#{manufactured_last_week}
      BTH222,Bath Oil,fluid_oz,7.49,90,Personal Care,false,,,,10,,2025-04-01
      MED333,Cough Syrup,milliliters,5.99,150,Medicine,true,CS999,#{medium_expiration},25,5,#{manufactured_last_week}
    CSV
  
    send_data sample_data,
              filename: "sample_products.csv",
              type: "text/csv",
              disposition: "attachment"
  end

  private

  def verify_file_type
    return if params[:file].content_type == 'text/csv'
  
    redirect_to @location, alert: "Only CSV files are allowed"
  end

  def set_location
    @location = Location.find(params[:id])
  end

  def location_params
    params.require(:location).permit(:name, :address, :city, :state, :zip_code, :country, :location_uid)
  end

  def generate_csv(items)
    CSV.generate(headers: true) do |csv|
      csv << ['SKU', 'Product Name', 'Unit Type', 'Category', 'Quantity', 'Low Stock Alert', 'Unit Price', 
              'Total Value', 'Perishable', 'Batch Number', 'Manufactured Date', 'Expiration Date', 'Notification Days']

      items.each do |item|
        product = item.product
        batch = item.batch

        csv << [
          product.sku,
          product.name,
          item.unit_type,
          product.category&.name || 'N/A',
          item.quantity,
          item.low_threshold || 'N/A',
          product.price,
          item.quantity * product.price,
          product.perishable? ? 'Yes' : 'No',
          batch&.batch_number || 'N/A',
          batch&.manufactured_date&.strftime("%Y-%m-%d") || 'N/A',
          batch&.expiration_date&.strftime("%Y-%m-%d") || 'N/A',
          batch&.notification_days_before_expiration || 'N/A'
        ]
      end
    end
  end
end
