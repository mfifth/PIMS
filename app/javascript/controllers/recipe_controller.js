import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]

  connect() {
    this.originalValues = this.collectValues()
  }

  collectValues() {
    const inputs = this.formTarget.querySelectorAll('input, select')
    return Array.from(inputs).reduce((acc, input) => {
      acc[input.name] = input.value
      return acc
    }, {})
  }

  hasChanges() {
    const currentValues = this.collectValues()
    return Object.keys(currentValues).some(key => 
      currentValues[key] !== this.originalValues[key]
    )
  }

  beforeSubmit(event) {
    if (!this.hasChanges()) {
      event.preventDefault()
      alert("No changes detected")
    }
  }
}