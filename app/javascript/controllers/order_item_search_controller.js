import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "input", "results", "itemsList", "hiddenInputs", "total", "location"
  ]

  connect() {
    this.initializeExistingItems()
    this.updateTotal()
  }

  initializeExistingItems() {
    this.itemsListTarget.querySelectorAll("[data-key]").forEach(wrapper => {
      const quantityInput = wrapper.querySelector(".quantity-input")
      const priceInput = wrapper.querySelector("input[name*='[price]']")
      const unitSelect = wrapper.querySelector("select[name*='[unit]']")

      const price = parseFloat(wrapper.dataset.price || priceInput?.value || "0")

      wrapper.dataset.price = price
      wrapper.dataset.baseUnit = unitSelect?.dataset.baseUnit || ""
      wrapper.dataset.conversionRates = unitSelect?.dataset.conversionRates || "{}"
    })
  }

  search() {
    const query = this.inputTarget.value.trim()
    const locationId = this.locationTarget.value
    if (!query || !locationId) return (this.resultsTarget.innerHTML = "")

    fetch(`/inventory_items/search?query=${encodeURIComponent(query)}&location_id=${locationId}`)
      .then(r => r.json())
      .then(data => {
        this.resultsTarget.innerHTML = ""
        data.forEach(item => {
          const li = document.createElement("li")
          li.className = "px-4 py-2 hover:bg-gray-100 cursor-pointer"
          li.textContent = `${item.product_name} - ($${item.price})`
          li.addEventListener("click", () => this.addItem(item))
          this.resultsTarget.appendChild(li)
        })
      })
  }

  addItem(item) {
    const key = `${item.item_type}-${item.id}`
    const existingItem = this.itemsListTarget.querySelector(`[data-key="${key}"]`)
    if (existingItem) {
      const quantityInput = existingItem.querySelector('.quantity-input')
      quantityInput.value = parseInt(quantityInput.value) + 1
      this.updateTotal()
      return
    }

    const index = this.itemsListTarget.querySelectorAll('[data-key]').length

    const unitOptionsHtml = (item.unit_options || []).map(opt =>
      `<option value="${opt.value}" ${opt.value === item.unit_type ? 'selected' : ''}>${opt.label}</option>`
    ).join("")

    const unitSelect = item.item_type === "InventoryItem"
      ? `<select name="order[order_items_attributes][${index}][unit]" 
                class="unit-select mt-1 border rounded px-2 py-1"
                data-base-unit="${item.unit_type || ''}"
                data-conversion-rates='${JSON.stringify(item.conversion_rates || {})}'
                data-action="change->order-item-search#updateTotal">
                  ${unitOptionsHtml}
          </select>
        `
      : ""

    const wrapper = document.createElement("div")
    wrapper.className = "grid grid-cols-5 gap-4 items-center p-3 bg-white rounded shadow-sm mb-3"
    wrapper.dataset.key = key
    wrapper.dataset.price = item.price
    wrapper.dataset.baseUnit = item.unit_type || ""
    wrapper.dataset.conversionRates = JSON.stringify(item.conversion_rates || {})

    wrapper.innerHTML = `
      <div class="col-span-2">
        <div class="font-medium text-gray-900">${item.product_name}</div>
        <div class="text-sm text-gray-500">$${item.price.toFixed(2)}</div>
      </div>
      <div>${unitSelect}</div>
      <div>
        <input type="number"
               name="order[order_items_attributes][${index}][quantity]"
               value="1"
               min="0"
               class="quantity-input w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
               data-action="input->order-item-search#updateTotal">
      </div>
      <div class="flex justify-end space-x-2">
        <button type="button"
                aria-label="Remove item"
                class="text-red-600 hover:text-red-800 focus:outline-none"
                data-action="click->order-item-search#removeItem"
                data-key="${key}">&times;</button>
        <input type="hidden" name="order[order_items_attributes][${index}][item_id]" value="${item.id}">
        <input type="hidden" name="order[order_items_attributes][${index}][item_type]" value="${item.item_type}">
        <input type="hidden" name="order[order_items_attributes][${index}][price]" value="${item.price}">
        <input type="hidden" name="order[order_items_attributes][${index}][location_id]" value="${item.location_id}">
      </div>
    `

    this.itemsListTarget.appendChild(wrapper)
    this.inputTarget.value = ""
    this.resultsTarget.innerHTML = ""
    this.updateTotal()
  }

  removeItem(e) {
    const key = e.target.dataset.key
    const el = this.itemsListTarget.querySelector(`[data-key="${key}"]`)

    if (el) {
      const inputs = el.querySelectorAll('input, select')
      inputs.forEach(input => {
        if (input.name && input.name.match(/\[(quantity|item_id|item_type|price|unit)\]$/)) {
          const newInput = document.createElement("input")
          newInput.type = "hidden"
          newInput.name = input.name.replace(/\[(\w+)\]$/, '[_destroy]')
          newInput.value = "1"
          this.hiddenInputsTarget.appendChild(newInput)
        }
      })

      el.remove()
      this.updateTotal()
    }
  }

  updateTotal() {
    let total = 0.0

    this.itemsListTarget.querySelectorAll("[data-key]").forEach(wrapper => {
      const price = parseFloat(wrapper.dataset.price || "0")
      const baseUnit = wrapper.dataset.baseUnit || null
      const conversionRates = JSON.parse(wrapper.dataset.conversionRates || "{}")

      const quantityInput = wrapper.querySelector(".quantity-input")
      const unitSelect = wrapper.querySelector(".unit-select")

      const quantity = parseFloat(quantityInput?.value || "0")
      const selectedUnit = unitSelect?.value || baseUnit

      let adjustedQuantity = quantity

      // Only apply unit conversion if it's an InventoryItem with unit select
      if (unitSelect && selectedUnit && selectedUnit !== baseUnit && conversionRates[selectedUnit]) {
        const rate = conversionRates[selectedUnit]
        adjustedQuantity = quantity / rate // Convert to base unit quantity
      }

      total += adjustedQuantity * price
    })

    this.totalTarget.textContent = `Total: $${total.toFixed(2)}`
  }
}