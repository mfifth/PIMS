import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "itemsList", "hiddenInputs"]
  static values = { batchId: Number }

  timeout = null

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      const q = this.inputTarget.value.trim()
      if (!q) {
        this.resultsTarget.innerHTML = ""
        return
      }

      fetch(`/batches/search?query=${encodeURIComponent(q)}&batch_id=${this.batchIdValue}`)
        .then(r => r.json())
        .then(data => {
          this.resultsTarget.innerHTML = ""
          data.forEach(item => {
            const li = document.createElement("li")
            li.className = "px-4 py-2 hover:bg-gray-100 cursor-pointer"
            // include sku and unit_type here:
            li.textContent = `${item.product_name} (SKU: ${item.sku}, Unit: ${item.unit_type}) — ${item.location_name} (Qty: ${item.quantity})`
            li.addEventListener("click", () => this.addItem(item))
            this.resultsTarget.appendChild(li)
          })
        })
    }, 200)
  }

  addItem(item) {
    // prevent duplicates
    if (this.hiddenInputsTarget.querySelector(`input[value="${item.id}"]`)) return

    // hidden input
    const hidden = document.createElement("input")
    hidden.type = "hidden"
    hidden.name = "batch[inventory_item_ids][]"
    hidden.value = item.id
    this.hiddenInputsTarget.appendChild(hidden)

    // visible list entry with remove button
    const li = document.createElement("li")
    li.dataset.itemId = item.id
    li.innerHTML = `
      ${item.product_name} (SKU: ${item.sku}, Unit: ${item.unit_type}) — ${item.location_name} (Qty: ${item.quantity})
      <button type="button"
              class="ml-2 text-red-600 hover:underline"
              data-action="click->inventory-search#removeItem"
              data-item-id="${item.id}">
        ✕
      </button>
    `
    this.itemsListTarget.appendChild(li)

    // clear search
    this.inputTarget.value = ""
    this.resultsTarget.innerHTML = ""
  }

  removeItem(e) {
    const id = e.target.dataset.itemId
    // remove list item
    const li = this.itemsListTarget.querySelector(`li[data-item-id="${id}"]`)
    if (li) li.remove()
    // remove hidden input
    const hidden = this.hiddenInputsTarget.querySelector(`input[value="${id}"]`)
    if (hidden) hidden.remove()
  }
}
