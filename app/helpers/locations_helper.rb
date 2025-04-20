module LocationsHelper
  def filter_link_class(filter_type, value)
    active = case filter_type
             when :perishable then params[:perishable].present? && to_bool(params[:perishable]) == value
             when :low_stock then params[:low_stock].present? && to_bool(params[:low_stock]) == value
             when :expiring then params[:expiring].present? && to_bool(params[:expiring]) == value
             else
               params[:perishable].blank? && params[:low_stock].blank? && params[:expiring].blank?
             end

    base_classes = "px-3 py-1 rounded transition-colors duration-200"
    active ? "#{base_classes} bg-blue-500 text-white" : "#{base_classes} bg-gray-200 text-gray-700 hover:bg-gray-300"
  end

  def to_bool(param)
    ActiveRecord::Type::Boolean.new.cast(param)
  end
end