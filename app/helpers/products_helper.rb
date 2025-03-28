module ProductsHelper
  def show_price(product)
    product.price.zero? ? nil : "Price: #{product.price} |"
  end

  def show_batch_info(product)
    product.batch ? "MFG: #{product.batch.manufactured_date} - EXP: #{product.batch.expiration_date} |" : nil
  end
end
