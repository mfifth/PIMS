import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "itemsList", "hiddenInputs"]
  static values = { batchId: Number }

  timeout = null

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      const query = this.inputTarget.value.trim()
      if (query.length === 0) {
        this.resultsTarget.innerHTML = ""
        return
      }

      const url = `/batches/search?query=${encodeURIComponent(query)}&batch_id=${this.batchIdValue}`

      fetch(url)
        .then(response => response.json())
        .then(data => {
          this.resultsTarget.innerHTML = ""
          data.forEach(item => {
            const li = document.createElement("li")
            li.classList.add("px-4", "py-2", "hover:bg-gray-100", "cursor-pointer")
            li.textContent = `${item.product_name} — ${item.location_name} (Qty: ${item.quantity})`
            li.addEventListener("click", () => this.addItem(item))
            this.resultsTarget.appendChild(li)
          })
        })
    }, 200)
  }

  addItem(item) {
    // Prevent duplicate addition
    if (this.hiddenInputsTarget.querySelector(`input[value="${item.id}"]`)) return

    // Add hidden input
    const hidden = document.createElement("input")
    hidden.type = "hidden"
    hidden.name = "batch[inventory_item_ids][]"
    hidden.value = item.id
    this.hiddenInputsTarget.appendChild(hidden)

    // Add to visible list with remove button
    const li = document.createElement("li")
    li.dataset.itemId = item.id
    li.innerHTML = `
      ${item.product_name} — ${item.location_name} (Qty: ${item.quantity})
      <button type="button" class="ml-2 text-red-600 hover:underline" data-action="click->inventory-search#removeItem" data-item-id="${item.id}">✕</button>
    `
    this.itemsListTarget.appendChild(li)

    // Clear search input and results
    this.inputTarget.value = ""
    this.resultsTarget.innerHTML = ""
  }

  removeItem(event) {
    const itemId = event.target.dataset.itemId

    // Remove from visible list
    const li = this.itemsListTarget.querySelector(`li[data-item-id="${itemId}"]`)
    if (li) li.remove()

    // Remove hidden input
    const hiddenInput = this.hiddenInputsTarget.querySelector(`input[value="${itemId}"]`)
    if (hiddenInput) hiddenInput.remove()
  }
}
