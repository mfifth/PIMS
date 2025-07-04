import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "input", "results", "itemsList", "hiddenInputs", "total", "location"
  ]

  connect() {
    this.updateTotal()
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

    const itemsCount = this.itemsListTarget.querySelectorAll('[data-key]').length
    const index = itemsCount

    const wrapper = document.createElement("div")
    wrapper.className = "flex items-center justify-between p-3 bg-white rounded shadow-sm mb-3"
    wrapper.dataset.key = key

    wrapper.innerHTML = `
      <div class="flex flex-col">
        <span class="font-medium text-gray-900">${item.product_name}</span>
        <span class="text-sm text-gray-500">$${item.price.toFixed(2)}</span>
      </div>
      <div class="flex items-center space-x-3">
        <input type="number"
              name="order[order_items_attributes][${index}][quantity]"
              value="1" min="1"
              class="quantity-input w-20 px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-indigo-500"
              data-price="${item.price.toFixed(2)}"
              data-action="input->order-item-search#updateTotal">

        <button type="button"
                aria-label="Remove item"
                class="text-red-600 hover:text-red-800 focus:outline-none"
                data-action="click->order-item-search#removeItem"
                data-key="${key}">
          &times;
        </button>

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
    if (!el) return

    // Find the index in the field name
    const idInput = el.querySelector('input[name*="[id]"]')
    const indexMatch = idInput?.name.match(/\[order_items_attributes\]\[(\d+)\]/) || 
                      idInput?.name.match(/\[(\d+)\]\[id\]/)

    if (idInput && indexMatch) {
      const index = indexMatch[1]

      // Append _destroy and id as hidden inputs
      this.hiddenInputsTarget.insertAdjacentHTML('beforeend', `
        <input type="hidden" name="order[order_items_attributes][${index}][id]" value="${idInput.value}">
        <input type="hidden" name="order[order_items_attributes][${index}][_destroy]" value="1">
      `)
    }

    el.remove()
    this.updateTotal()
  }

  updateTotal() {
    let total = 0.0
    this.itemsListTarget.querySelectorAll(".quantity-input").forEach(input => {
      const price = parseFloat(input.dataset.price || "0")
      const quantity = parseFloat(input.value || "0")
      total += price * quantity
    })
    this.totalTarget.textContent = `Total: $${total.toFixed(2)}`
  }
}
