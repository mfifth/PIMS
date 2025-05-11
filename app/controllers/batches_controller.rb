class BatchesController < ApplicationController
  before_action :set_batch, only: [:show, :edit, :update, :destroy]
  before_action :require_admin!, only: [:create, :update, :destroy, :edit, :new]

  def index
    @batches = Current.account.batches.left_joins(:products).distinct
  
    if params[:query].present?
      query = "%#{params[:query]}%"
      adapter = ActiveRecord::Base.connection.adapter_name.downcase
      like = adapter.include?("postgresql") ? "ILIKE" : "LIKE"
  
      @batches = @batches.where(
        "products.name #{like} :q OR batch_number #{like} :q OR expiration_date #{like} :q",
        q: query
      )

    else
      @batches = @batches.order(expiration_date: :asc)
    end
  
    @batches = @batches.page(params[:page]).per(5)
  
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end  

  def show
  end

  def new
    @batch = Batch.new
  end

  def create
    @batch = Batch.new(batch_params.merge(account_id: Current.account.id))
    if @batch.save
      redirect_to @batch, notice: t('notifications.batch_created')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @batch.update(batch_params)
      redirect_to @batch, notice: t('notifications.batch_updated')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @batch.products.update_all(perishable: false)
    @batch.destroy

    respond_to do |format|
      format.html { redirect_to batches_url, notice: t('notifications.batch_deleted') }
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
