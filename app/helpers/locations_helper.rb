module LocationsHelper
  def filter_link_class(filter_type, filter_value)
    base_classes = "px-3 py-1 rounded-lg transition"
    
    if filter_type.nil? && filter_value.nil?
      active = params[:perishable].blank? && params[:low_stock].blank?
    else
      current_value = params[filter_type]
      active = current_value == filter_value.to_s
    end

    active ? "#{base_classes} bg-gray-200" : base_classes
  end
end