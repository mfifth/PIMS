module LocationsHelper
  def filter_link_class(filter_type, value)
    active = case filter_type
             when :perishable then params[:perishable] == value.to_s
             when :low_stock then params[:low_stock] == value.to_s
             when :expiring then params[:expiring] == value.to_s
             else params[:perishable].blank? && params[:low_stock].blank? && params[:expiring].blank?
             end
  
    active ? "bg-blue-500 text-white px-3 py-1 rounded" : "bg-gray-200 text-gray-700 px-3 py-1 rounded hover:bg-gray-300"
  end
end