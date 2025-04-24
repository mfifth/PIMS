require 'csv'

class LocationsController < ApplicationController
  before_action :set_location, only: %i[show edit update destroy import_products]
  before_action :verify_file_type, only: [:import_products]

  def index
    @locations = Current.account.locations.includes(:inventory_items)
  end

  def show
    @active_filters = {
      perishable: params[:perishable],
      low_stock: params[:low_stock]
    }

    @inventory_items = @location.inventory_items
                  .includes(product: [:category, :batch])
                  .order('products.name ASC')
  
    if params[:perishable].present?
      @inventory_items = @inventory_items.where(products: { perishable: params[:perishable] })
    end
  
    if params[:low_stock] == 'true'
      @inventory_items = @inventory_items.where('inventory_items.quantity <= inventory_items.low_threshold')
    end

    if params[:expiring] == 'true'
      @inventory_items = @inventory_items.joins(product: :batch)
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
    Product.find(params[:product_id]).update(batch_id: params[:batch_id], category_id: params[:category_id])
    InventoryItem.find_by(location_id: params[:location_id], product_id: params[:product_id])
    .update(quantity: params[:quantity])

    redirect_back fallback_location: '/', notice: t('notifications.inventory_updated')
  end

  # In your LocationsController
  def inventory_data
    location = Location.find(params[:location_id])
    products = location.products
                       .includes(:batch, :inventory_items)
                       .where(inventory_items: { location_id: location.id })
                       .references(:inventory_items)
  
    render json: {
      products: products.map do |product|
        inventory_item = product.inventory_items.find_by(location_id: location.id)
        {
          id: product.id,
          name: product.name,
          quantity: inventory_item&.quantity || 0,
          category_id: product.category_id,
          batch_id: product.batch_id
        }
      end
    }
  end

  def categories
    @location = Location.find(params[:id])
    @page = params[:page] || 1
    @per_page = 5
    
    @categories = @location.inventory_items
                      .joins(product: :category)
                      .group('categories.id', 'categories.name')
                      .select(
                        'categories.id as category_id',
                        'categories.name as category_name',
                        'SUM(inventory_items.quantity) as total_quantity',
                        'SUM(inventory_items.quantity * products.price) as total_value'
                      )
                      .order('total_value DESC')
                      .page(@page)
                      .per(@per_page)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @location }
    end
  end

  def import_products
    if params[:file].present?
      tempfile = params[:file].tempfile
      file_path = Rails.root.join('tmp', "import_#{Time.now.to_i}.csv")
      FileUtils.mv(tempfile.path, file_path)

      CsvImportJob.perform_later(file_path.to_s, Current.user.id, @location.id)      
    else
      flash[:alert] = t('locations.csv_file_warning')
    end

    redirect_to @location, notice: t('locations.csv_import_notice')
  end

  def sample_csv
    sample_data = "sku,name,unit_type,price,quantity,category,perishable,batch_number,expiration_date,low_threshold,notification_days\n" +
                  "ABC123,Sample Product 1,units,19.99,100,Electronics,true,BATCH001,2025-12-31,10,7\n" +
                  "DEF456,Sample Product 2,pounds,29.99,50,Clothing,false,,,20,\n" +
                  "GHI789,Sample Product 3,ounces,9.99,200,Food,true,BATCH002,2026-06-30,30,14"
  
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
    params.require(:location).permit(:name, :address, :city, :state, :zip_code, :country)
  end

  def generate_csv(items)
    CSV.generate(headers: true) do |csv|
      csv << ['Product Name', 'SKU', 'Category', 'Quantity', 'Low Threshold', 'Unit Price', 
              'Total Value', 'Perishable', 'Batch Number', 'Expiration Date']

      items.each do |item|
        product = item.product
        batch = product.batch

        csv << [
          product.name,
          product.sku,
          product.category&.name || 'N/A',
          item.quantity,
          item.low_threshold,
          product.price,
          item.quantity * product.price,
          product.perishable? ? 'Yes' : 'No',
          product.perishable? ? (batch&.batch_number || 'N/A') : 'N/A',
          product.perishable? ? (batch&.expiration_date&.strftime("%Y-%m-%d") || 'Not set') : 'N/A'
        ]
      end
    end
  end
end
