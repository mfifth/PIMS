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
    "marginPct",
    "multiplierInput", 
    "ingredientQuantity",
    "ingredientCalculator"
  ]

  static values = {
    i18nMissingInventory: String,
    i18nInvalidPrice: String,
    i18nFromLocationPrice: String,
    i18nSelectLocation: String
  }

  connect() {
    this.recipeItems = Array.from(this.element.querySelectorAll('.recipe-item')).map(item => ({
      element: item,
      product: item.dataset.productName,
      quantity: parseFloat(item.dataset.quantity) || 0,
      unit: item.dataset.unit,
      translatedUnit: item.dataset.translatedUnit || item.dataset.unit,
      inventoryOptions: Array.from(item.querySelectorAll('.inventory-option')).map(opt => ({
        element: opt,
        locationId: opt.dataset.locationId,
        locationName: opt.dataset.locationName || 'Unknown Location',
        unitType: opt.dataset.inventoryUnit,
        translatedUnit: opt.dataset.translatedUnit || opt.dataset.inventoryUnit,
        price: parseFloat(opt.dataset.pricePerUnit) || 0
      }))
    }));

    this.updateIngredientQuantities()
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

  updateIngredientQuantities() {
    const multiplier = parseFloat(this.multiplierInputTarget.value) || 1
    this.ingredientQuantityTargets.forEach(el => {
      const base = parseFloat(el.dataset.baseQuantity) || 0
      el.textContent = (base * multiplier).toFixed(2)
    })
  }

  toggleIngredientsCalculator() {
    this.ingredientCalculatorTarget.classList.toggle("hidden")
  }

  formatFromLocationPrice(locationName, unitPrice, unitType, translatedUnit) {
    return this.i18nFromLocationPriceValue
      .replace("%{location}", locationName)
      .replace("%{price}", unitPrice.toFixed(2))
      .replace("%{unit}", translatedUnit || unitType);
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
      <option value="">${this.i18nSelectLocationValue}</option>
      ${completeLocations.map(locationId => `
        <option value="${locationId}">${allLocations[locationId]}</option>
      `).join('')}
    `;
  }

  recalculate() {
    const selectedLocationId = this.locationSelectTarget.value;
    if (!selectedLocationId) {
      this.resetTotals();
      return;
    }

    let totalCost = 0;
    let ingredientsHTML = '';

    this.recipeItems.forEach(item => {
      const displayUnit = item.translatedUnit || item.unit;
      const inventoryOption = item.inventoryOptions.find(
        opt => opt.locationId === selectedLocationId
      );

      if (!inventoryOption) {
        ingredientsHTML += `
          <div class="flex justify-between items-center py-2 border-b text-red-500">
            <div class="w-2/3">
              ${item.product} (${item.quantity} ${displayUnit})
              <div class="text-xs">${this.i18nMissingInventoryValue.replace("%{product}", item.product)}</div>
            </div>
            <div class="w-1/3 text-right font-mono">-</div>
          </div>
        `;
        return;
      }

      const conversionRate = this.getConversionRate(item.unit, inventoryOption.unitType);
      if (!conversionRate) {
        ingredientsHTML += `
          <div class="flex justify-between items-center py-2 border-b text-yellow-600">
            <div class="w-2/3">
              ${item.product} (${item.quantity} ${displayUnit})
              <div class="text-xs">${this.i18nInvalidPriceValue}</div>
            </div>
            <div class="w-1/3 text-right font-mono">-</div>
          </div>
        `;
        return;
      }

      const adjustedQty = item.quantity * conversionRate;
      const cost = adjustedQty * inventoryOption.price;
      totalCost += cost;

      const fromLocationText = this.formatFromLocationPrice(
        inventoryOption.locationName,
        inventoryOption.price,
        inventoryOption.unitType,
        inventoryOption.translatedUnit
      );

      ingredientsHTML += `
        <div class="flex justify-between items-center py-2 border-b">
          <div class="w-2/3">
            ${item.product} (${item.quantity} ${displayUnit})
            <div class="text-xs text-gray-500">
              ${fromLocationText}
            </div>
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

  resetTotals() {
    this.totalCostTarget.textContent = "0.00";
    this.profitTarget.textContent = "0.00";
    this.marginPctTarget.textContent = "0.00";
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