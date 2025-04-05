import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["batchFields", "newBatchFields"];

  connect() {
    this.toggleBatchFields();
    this.toggleNewBatchFields();
  }

  toggleBatchFields() {
    const perishableCheckbox = document.getElementById("perishable_checkbox");

    if (perishableCheckbox?.checked) {
      this.batchFieldsTarget.style.display = "block";
    } else {
      this.batchFieldsTarget.style.display = "none";
    }
  }

  toggleNewBatchFields() {
    const batchSelect = document.getElementById("batch_select");
  
    const fieldIds = [
      "product_batch_number",
      "product_expiration_date",
    ];
  
    if (batchSelect?.value) {
      fieldIds.forEach((id) => {
        const field = document.getElementById(id);
        if (field) {
          field.removeAttribute("required");
        }
      });
      this.newBatchFieldsTarget.style.display = "none";
    } else {
      this.newBatchFieldsTarget.style.display = "block";
  
      // Add required attributes when creating a new batch
      fieldIds.forEach((id) => {
        const field = document.getElementById(id);
        if (field) {
          field.setAttribute("required", "required");
        }
      });
    }
  }
  
}