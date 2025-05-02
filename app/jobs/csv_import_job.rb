class CsvImportJob < ApplicationJob
  def perform(file_contents, user_id, location_id)
    user = User.find_by(id: user_id)
    location = Location.find_by(id: location_id)
  
    CsvImporter.new(
      user: user,
      location: location,
      file_contents: file_contents
    ).import
  end
end