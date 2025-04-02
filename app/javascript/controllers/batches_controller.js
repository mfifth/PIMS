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
    if (batchSelect?.value) {
      this.newBatchFieldsTarget.style.display = "none";
    } else {
      this.newBatchFieldsTarget.style.display = "block";
    }
  }
}