import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["front", "back"]

  flip(event) {
    event.preventDefault()
    event.stopPropagation()
    
    // Toggle visibility
    this.frontTarget.classList.toggle("hidden")
    this.backTarget.classList.toggle("hidden")
  }

  // Ensure cards start in correct state
  connect() {
    this.backTarget.classList.add("hidden")
  }
}