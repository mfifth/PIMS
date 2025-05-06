// app/javascript/controllers/flip_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["front", "back"]

  flip(event) {
    // Prevent default action and stop propagation
    event.preventDefault()
    event.stopPropagation()
    
    this.frontTarget.classList.toggle("hidden")
    this.backTarget.classList.toggle("hidden")
  }

  // Add this to handle back button
  flipBack(event) {
    event.preventDefault()
    event.stopPropagation()
    this.flip(event)
  }
}