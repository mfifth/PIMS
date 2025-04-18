module ProductsHelper
  def show_price(product)
    return unless product.price.positive?
    "#{I18n.t('products.price')}: #{product.price} |"
  end

  def show_batch_info(product)
    return unless product.batch

    mfg = product.batch.manufactured_date || I18n.t('products.na')
    exp = product.batch.expiration_date || I18n.t('products.na')
    "#{I18n.t('products.mfg')}: #{mfg} - #{I18n.t('products.exp')}: #{exp} |"
  end
end
