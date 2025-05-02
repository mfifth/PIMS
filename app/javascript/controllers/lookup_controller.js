import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["locationSelect", "quantity", "lowThreshold", "unitType"]
  static values = {
    productId: Number
  }

  async fetchInventory() {
    const locationId = this.locationSelectTarget.value
    if (!locationId || !this.productIdValue) return

    const url = `/inventory_items/lookup?product_id=${this.productIdValue}&location_id=${locationId}`

    try {
      const response = await fetch(url)
      if (!response.ok) throw new Error("Network response was not ok")

      const data = await response.json()

      this.quantityTarget.value = data.quantity || ""
      this.lowThresholdTarget.value = data.low_threshold || ""

      // Set unit_type if available
      if (data.unit_type) {
        this.unitTypeTarget.value = data.unit_type
      }
    } catch (error) {
      console.error("Failed to fetch inventory info:", error)
    }
  }
}
