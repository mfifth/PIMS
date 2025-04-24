# spec/helpers/square_helper_spec.rb
require 'rails_helper'

RSpec.describe SquareHelper, type: :helper do
  let(:account) { create(:account) }
  let(:location) { create(:location, account: account, location_uid: 'loc123') }
  let(:product) { create(:product, account: account, sku: 'prod123', unit_type: 'grams') }
  let(:recipe) { create(:recipe, account: account, uid: 'recipe123') }
  let(:inventory_item) { create(:inventory_item, product: product, location: location, quantity: 100) }

  before do
    # Stub the inventory item creation/update
    allow(InventoryItem).to receive(:find_or_initialize_by).and_return(inventory_item)
  end

  describe '#process_order' do
    context 'with a product order' do
      let(:order_data) do
        {
          "id" => "order123",
          "line_items" => [{
            "catalog_object_id" => "prod123",
            "quantity" => "2"
          }],
          "location_id" => "loc123"
        }
      end

      it 'deducts inventory for the product' do
        expect(inventory_item).to receive(:save!)
        helper.process_order(account, order_data)
        expect(inventory_item.quantity).to eq(98) # 100 - 2
      end
    end

    context 'with a recipe order' do
      let(:order_data) do
        {
          "id" => "order123",
          "line_items" => [{
            "catalog_object_id" => "recipe123",
            "quantity" => "3"
          }],
          "location_id" => "loc123"
        }
      end

      before do
        # Recipe with two ingredients
        create(:recipe_item, recipe: recipe, product: product, quantity: 0.5, unit: 'grams')
        create(:recipe_item, 
          recipe: recipe, 
          product: create(:product, account: account, sku: 'prod456', unit_type: 'ounces'), 
          quantity: 1, 
          unit: 'pounds'
        )
      end

      it 'deducts converted quantities for all recipe items' do
        helper.process_order(account, order_data)
        
        # First product (grams): 0.5g * 3 = 1.5g deducted
        expect(inventory_item.quantity).to eq(98.5) # 100 - 1.5
        
        # Second product (pounds → ounces conversion)
        # 1 pound = 16 ounces, so 1 pound * 3 = 48 ounces deducted
        second_inventory = InventoryItem.find_by(product: Product.find_by(sku: 'prod456'))
        expect(second_inventory.quantity).to eq(52) # Assuming it started at 100
      end
    end

    context 'with invalid units' do
      let(:order_data) do
        {
          "id" => "order123",
          "line_items" => [{
            "catalog_object_id" => "recipe123",
            "quantity" => "1"
          }],
          "location_id" => "loc123"
        }
      end

      before do
        create(:recipe_item, 
          recipe: recipe, 
          product: create(:product, account: account, sku: 'prod789', unit_type: 'liters'), 
          quantity: 1, 
          unit: 'grams'
        )
      end

      it 'skips conversion for incompatible units' do
        expect(Rails.logger).to receive(:warn).with(/Incompatible units/)
        helper.process_order(account, order_data)
      end
    end
  end

  describe '#convertible_units?' do
    it 'returns true for weight units' do
      expect(helper.convertible_units?('grams', 'ounces')).to be true
      expect(helper.convertible_units?('pounds', 'grams')).to be true
    end

    it 'returns true for volume units' do
      expect(helper.convertible_units?('liters', 'gallons')).to be true
    end

    it 'returns false for mixed unit types' do
      expect(helper.convertible_units?('grams', 'liters')).to be false
    end

    it 'returns false for units' do
      expect(helper.convertible_units?('units', 'grams')).to be false
    end
  end

  describe '#conversion_rate' do
    it 'returns correct rate for weight units' do
      expect(helper.conversion_rate('ounces', 'grams')).to be_within(0.001).of(28.3495)
      expect(helper.conversion_rate('pounds', 'ounces')).to eq(16)
    end

    it 'returns 1 for same units' do
      expect(helper.conversion_rate('grams', 'grams')).to eq(1)
    end

    it 'returns 1 for unconvertible units' do
      expect(helper.conversion_rate('grams', 'liters')).to eq(1)
    end
  end
end