import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "label", "text", "spinner"]

  submit() {
    if (this.inputTarget.files.length > 0) {
      this.showLoadingState()
      this.element.requestSubmit()
    }
  }

  showLoadingState() {
    this.textTarget.classList.add("hidden")
    this.spinnerTarget.classList.remove("hidden")
    this.labelTarget.classList.add("cursor-not-allowed", "bg-blue-400")
  }
}