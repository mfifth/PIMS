import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["batchFields", "newBatchFields"];
  static values = {
    batchFieldIds: { type: Array, default: ["product_batch_number", "product_expiration_date"] },
    productId: String
  };

  connect() {
    this.setupEventListeners();
    this.updateFieldsVisibility();
  }

  setupEventListeners() {
    const perishableCheckbox = document.getElementById("perishable_checkbox");
    const batchSelect = document.getElementById("batch_select");

    if (perishableCheckbox) {
      perishableCheckbox.addEventListener("change", this.updateFieldsVisibility.bind(this));
    }

    if (batchSelect) {
      batchSelect.addEventListener("change", this.updateNewBatchFields.bind(this));
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
    const batchSelect = document.getElementById("batch_select");
    const hasExistingBatch = batchSelect?.value;
    
    if (!isPerishable || !batchSelect) return;

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
}