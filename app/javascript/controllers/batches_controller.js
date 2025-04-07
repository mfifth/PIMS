import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["batchFields", "newBatchFields"];

  connect() {
    this.toggleBatchFields();
    this.toggleNewBatchFields();

    // Listen to changes for dynamic behavior
    document.getElementById("perishable_checkbox")?.addEventListener("change", () => {
      this.toggleBatchFields();
      this.toggleNewBatchFields();
    });

    document.getElementById("batch_select")?.addEventListener("change", () => {
      this.toggleNewBatchFields();
    });
  }

  toggleBatchFields() {
    const perishableCheckbox = document.getElementById("perishable_checkbox");
    if (perishableCheckbox?.checked) {
      this.batchFieldsTarget.style.display = "block";
    } else {
      this.batchFieldsTarget.style.display = "none";
      // Clean up validations when hidden
      this.setFieldRequirements([
        "product_batch_number",
        "product_expiration_date"
      ], false);
    }
  }

  toggleNewBatchFields() {
    const batchSelect = document.getElementById("batch_select");
    const perishableCheckbox = document.getElementById("perishable_checkbox");

    const fieldIds = [
      "product_batch_number",
      "product_expiration_date"
    ];

    if (!perishableCheckbox?.checked) return;

    if (batchSelect?.value) {
      this.newBatchFieldsTarget.style.display = "none";
      this.setFieldRequirements(fieldIds, false);
    } else {
      this.newBatchFieldsTarget.style.display = "block";
      this.setFieldRequirements(fieldIds, true);
    }
  }

  setFieldRequirements(ids, required) {
    ids.forEach((id) => {
      const field = document.getElementById(id);
      if (field) {
        if (required) {
          field.setAttribute("required", "required");
        } else {
          field.removeAttribute("required");
        }
      }
    });
  }
}
