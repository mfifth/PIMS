class NotificationMailer < ApplicationMailer
  default from: 'notifications@example.com' # Change this to your sender email

  def low_inventory_alert(inventory_item, user)
    @inventory_item = inventory_item
    @user = user
    @product = inventory_item.product
    @location = inventory_item.location

    mail(
      to: @user.email_address,
      subject: "Low Inventory Alert: #{@product.name} at #{@location.name}"
    )
  end

  def upcoming_expiration_date(user, batch)
    @user = user
    @batch = batch
    mail(to: @user.email_address, subject: "Upcoming Expiration Date for Batch ##{@batch.batch_number}")
  end
end
