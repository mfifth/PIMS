class SuppliersController < ApplicationController
  include Authentication

  before_action :set_supplier, only: %i[show edit update destroy]

  # GET /suppliers
  def index
    @suppliers = Supplier.where(account_id: Current.account.id)
  end

  # GET /suppliers/1
  def show
  end

  # GET /suppliers/new
  def new
    @supplier = Supplier.new
  end

  # POST /suppliers
  def create
    @supplier = Current.account.suppliers.build(supplier_params)

    if @supplier.save
      redirect_to @supplier, notice: "Supplier was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /suppliers/1/edit
  def edit
  end

  # PATCH/PUT /suppliers/1
  def update
    if @supplier.update(supplier_params)
      redirect_to @supplier, notice: "Supplier was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /suppliers/1
  def destroy
    @supplier.destroy
    redirect_to suppliers_url, notice: "Supplier was successfully deleted."
  end

  private

  def set_supplier
    @supplier = Current.account.suppliers.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to suppliers_path, alert: "Supplier not found."
  end

  def supplier_params
    params.require(:supplier).permit(:name, :contact_name, :contact_email, :phone_number)
  end
end
