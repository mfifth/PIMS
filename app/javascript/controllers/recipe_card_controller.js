import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "details", 
    "analysis",
    "locationSelect",
    "ingredientsList",
    "priceInput", 
    "totalCost", 
    "profit", 
    "marginPct"
  ]

  connect() {
    this.recipeItems = Array.from(this.element.querySelectorAll('.recipe-item')).map(item => ({
      element: item,
      product: item.dataset.productName,
      quantity: parseFloat(item.dataset.quantity) || 0,
      unit: item.dataset.unit,
      inventoryOptions: Array.from(item.querySelectorAll('.inventory-option')).map(opt => ({
        element: opt,
        locationId: opt.dataset.locationId,
        locationName: opt.dataset.locationName || 'Unknown Location',
        unitType: opt.dataset.inventoryUnit,
        price: parseFloat(opt.dataset.pricePerUnit) || 0
      }))
    }));

    this.initializeLocationOptions();
    this.recalculate();
  }

  toggle() {
    this.detailsTarget.classList.toggle("hidden");
    this.analysisTarget.classList.toggle("hidden");
    
    if (!this.analysisTarget.classList.contains("hidden")) {
      this.initializeLocationOptions();
      this.recalculate();
    }
  }

  initializeLocationOptions() {
    const allLocations = {};
    this.recipeItems.forEach(item => {
      item.inventoryOptions.forEach(option => {
        allLocations[option.locationId] = option.locationName;
      });
    });

    const completeLocations = Object.keys(allLocations).filter(locationId => {
      return this.recipeItems.every(item => 
        item.inventoryOptions.some(opt => opt.locationId === locationId)
      );
    });

    this.locationSelectTarget.innerHTML = `
      <option value="">Select a location</option>
      ${completeLocations.map(locationId => `
        <option value="${locationId}">${allLocations[locationId]}</option>
      `).join('')}
    `;
  }

  recalculate() {
    const selectedLocationId = this.locationSelectTarget.value;
    if (!selectedLocationId) return;

    let totalCost = 0;
    let ingredientsHTML = '';

    this.recipeItems.forEach(item => {
      const inventoryOption = item.inventoryOptions.find(
        opt => opt.locationId === selectedLocationId
      );

      if (!inventoryOption) return;

      const conversionRate = this.getConversionRate(item.unit, inventoryOption.unitType);
      if (!conversionRate) return;

      const adjustedQty = item.quantity * conversionRate;
      const cost = adjustedQty * inventoryOption.price;
      totalCost += cost;

      ingredientsHTML += `
        <div class="flex justify-between items-center py-2 border-b">
          <div class="w-2/3">
            ${item.product} (${item.quantity} ${item.unit})
          </div>
          <div class="w-1/3 text-right font-mono">$${cost.toFixed(2)}</div>
        </div>
      `;
    });

    this.ingredientsListTarget.innerHTML = ingredientsHTML;

    const price = parseFloat(this.priceInputTarget.value) || 0;
    const profit = price - totalCost;
    const margin = price > 0 ? ((profit / price) * 100).toFixed(2) : "0.00";

    this.totalCostTarget.textContent = totalCost.toFixed(2);
    this.profitTarget.textContent = profit.toFixed(2);
    this.marginPctTarget.textContent = margin;
  }

  getConversionRate(fromUnit, toUnit) {
    const rates = {
      grams:      { grams: 1, kilograms: 0.001, ounces: 1 / 28.3495, pounds: 1 / 453.592 },
      kilograms:  { grams: 1000, kilograms: 1, ounces: 35.274, pounds: 2.20462 },
      ounces:     { grams: 28.3495, kilograms: 0.0283495, ounces: 1, pounds: 1 / 16 },
      pounds:     { grams: 453.592, kilograms: 0.453592, ounces: 16, pounds: 1 },
      liters:     { liters: 1, gallons: 1 / 3.78541, fluid_oz: 33.814, milliliters: 1000 },
      gallons:    { liters: 3.78541, gallons: 1, fluid_oz: 128, milliliters: 3785.41 },
      fluid_oz:   { liters: 0.0295735, gallons: 1 / 128, fluid_oz: 1, milliliters: 29.5735 },
      milliliters:{ liters: 0.001, gallons: 0.000264172, fluid_oz: 0.033814, milliliters: 1 },
      units:      { units: 1 }
    };

    return rates[fromUnit]?.[toUnit] ?? null;
  }
}