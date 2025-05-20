import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["front", "back"]

  flip(event) {
    event.preventDefault()
    event.stopPropagation()
    
    this.frontTarget.classList.toggle("hidden")
    this.backTarget.classList.toggle("hidden")
  }

  connect() {
    this.backTarget.classList.add("hidden")
  }
}