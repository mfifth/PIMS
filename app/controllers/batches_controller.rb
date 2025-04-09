class BatchesController < ApplicationController
  before_action :set_batch, only: [:show, :edit, :update, :destroy]

  # GET /batches
  def index
    if params[:query].present?
      @batches = Current.account.batches
                 .left_joins(:products)
                 .order(:expiration_date)
                 .where("products.name LIKE ? OR batch_number LIKE ? OR expiration_date LIKE ?", 
                 "%#{params[:query]}%", "%#{params[:query]}%", "%#{params[:query]}%")
                 .page(params[:page]).per(5).distinct
    else
      @batches = Current.account.batches.left_joins(:products).page(params[:page]).per(5).distinct
    end

    respond_to do |format|
      format.html
      format.turbo_stream do
        if @batches.any?
          render turbo_stream: [
            turbo_stream.append("batches", partial: "batches/batch", collection: @batches),
            turbo_stream.replace("infinite-scroll-metadata", partial: "batches/next_page_metadata", locals: { next_page: @batches.next_page })
          ]
        else
          render turbo_stream: ""
        end
      end
    end
  end

  # GET /batches/:id
  def show
  end

  # GET /batches/new
  def new
    @batch = Batch.new
  end

  # POST /batches
  def create
    @batch = Batch.new(batch_params.merge(account_id: Current.account.id))
    if @batch.save
      redirect_to @batch, notice: 'Batch was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /batches/:id/edit
  def edit
  end

  # PATCH/PUT /batches/:id
  def update
    if @batch.update(batch_params)
      redirect_to @batch, notice: 'Batch was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /batches/:id
  def destroy
    @batch.destroy

    respond_to do |format|
      format.html { redirect_to batches_url, notice: 'Batch was successfully deleted.' }
      format.turbo_stream { render turbo_stream: turbo_stream.remove("batch_#{@batch.id}") }
    end
  end

  private

  def set_batch
    @batch = Batch.includes(:account, products: :inventory_items).find(params[:id])
  end

  def batch_params
    params.require(:batch).permit(:batch_number, :manufactured_date, :notification_days_before_expiration, :expiration_date, :supplier_id, product_ids: [])
  end
end
