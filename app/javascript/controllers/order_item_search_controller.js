import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "input", "results", "itemsList", "hiddenInputs", "total", "location"
  ]

  connect() {
    this.updateTotal()
    this.itemsListTarget.querySelectorAll(".quantity-input").forEach(input => {
      input.addEventListener("input", () => this.updateTotal())
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
    const existing = this.hiddenInputsTarget.querySelector(
      `input[name="order[order_items_attributes][][item_id]"][value="${item.id}"]`
    )
    if (existing) return

    // Generate a unique id for new items to match form structure
    const newId = `new_${Date.now()}`

    const wrapper = document.createElement("div")
    wrapper.className = "flex items-center justify-between p-3 bg-white rounded shadow-sm mb-3"
    wrapper.dataset.orderItemId = newId

    wrapper.innerHTML = `
      <div class="flex flex-col">
        <span class="font-medium text-gray-900">${item.product_name}</span>
        <span class="text-sm text-gray-500">$${item.price.toFixed(2)}</span>
      </div>
      <div class="flex items-center space-x-3">
        <input type="number" name="order[order_items_attributes][][quantity]" value="1" min="1"
               class="quantity-input w-20 px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
               data-price="${item.price.toFixed(2)}"
               data-action="input->order-item-search#updateTotal">
        <button type="button"
                aria-label="Remove item"
                class="text-red-600 hover:text-red-800 focus:outline-none"
                data-action="click->order-item-search#removeItem"
                data-item-id="${newId}">
          &times;
        </button>
        <input type="hidden" name="order[order_items_attributes][][item_id]" value="${item.id}">
        <input type="hidden" name="order[order_items_attributes][][item_type]" value="${item.item_type}">
        <input type="hidden" name="order[order_items_attributes][][price]" value="${item.price}">
        <input type="hidden" name="order[order_items_attributes][][location_id]" value="${item.location_id}">
        <input type="hidden" name="order[order_items_attributes][][_destroy]" value="false" data-destroy-field="true">
      </div>
    `

    this.itemsListTarget.appendChild(wrapper)
    this.inputTarget.value = ""
    this.resultsTarget.innerHTML = ""
    this.updateTotal()
  }

  removeItem(e) {
    const id = e.target.dataset.itemId
    const el = this.itemsListTarget.querySelector(`[data-order-item-id="${id}"]`)
    if (el) {
      const destroyInput = el.querySelector('input[data-destroy-field="true"]')
      if (destroyInput) destroyInput.value = '1'  // mark for deletion
      el.style.display = 'none'  // hide it visually
    }
    this.updateTotal()
  }

  updateTotal() {
    let total = 0.0
    this.itemsListTarget.querySelectorAll(".quantity-input").forEach(input => {
      const parent = input.closest('[data-order-item-id]')
      if (parent && parent.style.display === 'none') return  // skip hidden (deleted) items
      const price = parseFloat(input.dataset.price)
      const quantity = parseFloat(input.value) || 0
      total += price * quantity
    })
    this.totalTarget.textContent = `Total: $${total.toFixed(2)}`
  }
}
