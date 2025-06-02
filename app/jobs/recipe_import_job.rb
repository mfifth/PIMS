class RecipeImportJob < ApplicationJob
  queue_as :default

  def perform(file_contents, user_id)
    user = User.find_by(id: user_id)
    return unless user

    RecipeImportService.new(
      user: user,
      file_contents: file_contents
    ).import

    Notification.create!(
      account: user.account,
      message: I18n.t('recipes.csv_import_success'),
      notification_type: :notice
    )
  rescue => e
    Rails.logger.error "[RecipeImportJob] Failed to import: #{e.message}\n#{e.backtrace.join("\n")}"
    Notification.create!(
      account: user.account,
      message: I18n.t('recipes.csv_import_failed', error: e.message),
      notification_type: :alert
    )
  end
end
