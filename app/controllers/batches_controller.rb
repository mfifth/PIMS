class BatchesController < ApplicationController
  before_action :set_batch, only: [:show, :edit, :update, :destroy]

  # GET /batches
  def index
    @batches = Current.account.batches.includes(:products).order(:expiration_date)
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
    redirect_to batches_url, notice: 'Batch was successfully deleted.'
  end

  private

  def set_batch
    @batch = Batch.includes(:account).find(params[:id])
  end

  def batch_params
    params.require(:batch).permit(:batch_number, :manufactured_date, :expiration_date, :supplier_id, product_ids: [])
  end
end
