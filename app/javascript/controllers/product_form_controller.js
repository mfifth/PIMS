import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "batchFields", 
    "newBatchFields",
    "locationSelect", 
    "quantity", 
    "lowThreshold", 
    "unitType", 
    "price", 
    "batchSelect"
  ]
  static values = {
    batchFieldIds: { type: Array, default: ["product_batch_number", "product_expiration_date"] },
    productId: Number
  }

  connect() {
    this.setupEventListeners();
    this.updateFieldsVisibility();
  }

  // Batch-related methods
  setupEventListeners() {
    const perishableCheckbox = document.getElementById("perishable_checkbox");
    if (perishableCheckbox) {
      perishableCheckbox.addEventListener("change", this.updateFieldsVisibility.bind(this));
    }
  }

  toggleBatchFields() {
    const isPerishable = document.getElementById("perishable_checkbox")?.checked;
    this.batchFieldsTarget.style.display = isPerishable ? "block" : "none";
    
    if (!isPerishable) {
      this.setFieldsRequired(this.batchFieldIdsValue, false);
    }
  }

  updateFieldsVisibility() {
    this.toggleBatchFields();
    this.updateNewBatchFields();
  }

  updateNewBatchFields() {
    const isPerishable = document.getElementById("perishable_checkbox")?.checked;
    const hasExistingBatch = this.hasBatchSelectTarget && this.batchSelectTarget.value;
    
    if (!isPerishable || !this.hasBatchSelectTarget) return;

    const shouldShowNewBatchFields = !hasExistingBatch;
    this.newBatchFieldsTarget.style.display = shouldShowNewBatchFields ? "block" : "none";
    this.setFieldsRequired(this.batchFieldIdsValue, shouldShowNewBatchFields);
  }

  setFieldsRequired(fieldIds, required) {
    fieldIds.forEach((id) => {
      const field = document.getElementById(id);
      if (field) {
        field.toggleAttribute("required", required);
      }
    });
  }

  // Inventory lookup methods
  async fetchInventory() {
    const locationId = this.locationSelectTarget.value;
    if (!locationId || !this.productIdValue) return;

    const url = `/inventory_items/lookup?product_id=${this.productIdValue}&location_id=${locationId}`;

    try {
      const response = await fetch(url);
      if (!response.ok) throw new Error("Network response was not ok");

      const data = await response.json();
      console.log("API Response:", data);

      // Update inventory fields
      this.quantityTarget.value = data.quantity || "";
      this.lowThresholdTarget.value = data.low_threshold || "";
      this.unitTypeTarget.value = data.unit_type || "";
      this.priceTarget.value = data.price || "";
      
      // Update batch selection if available
      if (data.batch_id && this.hasBatchSelectTarget) {
        this.batchSelectTarget.value = data.batch_id.toString();
        this.updateNewBatchFields(); // Update fields based on batch selection
      }

    } catch (error) {
      console.error("Failed to fetch inventory info:", error);
    }
  }
}