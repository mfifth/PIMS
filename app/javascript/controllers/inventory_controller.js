import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["productSelection", "quantityField", "batchSelection", "submitBtn", "productSelect", "quantityInput", "batchSelect"]
  static values = { locationUrl: String }

  connect() {
    // Initialize elements
    this.locationSelect = this.element.querySelector('[name="location_id"]')
    this.setupEventListeners()
  }

  setupEventListeners() {
    this.locationSelect.addEventListener('change', this.handleLocationChange.bind(this))
  }

  async handleLocationChange(event) {
    const locationId = event.target.value

    if (locationId) {
      this.productSelectionTarget.style.display = "block"

      try {
        const response = await fetch(`/locations/${locationId}/inventory_data`)
        if (!response.ok) throw new Error("Network response was not ok")
        
        const data = await response.json()
        this.populateProductSelect(data.products)
      } catch (error) {
        console.error("Error fetching products:", error)
        // You might want to show an error message to the user here
      }
    } else {
      this.hideAllSections()
    }
  }

  populateProductSelect(products) {
    this.productSelectTarget.innerHTML = "<option value=''>Select a product</option>"
    products.forEach(product => {
      const option = document.createElement("option")
      option.value = product.id
      option.textContent = product.name
      option.dataset.quantity = product.quantity
      option.dataset.batchId = product.batch_id || ""
      this.productSelectTarget.appendChild(option)
    })
    
    // Add event listener after populating
    this.productSelectTarget.addEventListener('change', this.handleProductChange.bind(this))
  }

  handleProductChange(event) {
    const selectedOption = event.target.options[event.target.selectedIndex]
    const productId = event.target.value
    
    if (productId) {
      this.showAllSections()
      this.populateFormFields(selectedOption)
    } else {
      this.hideDependentSections()
    }
  }

  populateFormFields(selectedOption) {
    // Set quantity
    this.quantityInputTarget.value = selectedOption.dataset.quantity || 0
    
    // Set batch selection
    if (selectedOption.dataset.batchId) {
      this.batchSelectTarget.value = selectedOption.dataset.batchId
    } else {
      this.batchSelectTarget.value = ""
    }
  }

  showAllSections() {
    this.quantityFieldTarget.style.display = "block"
    this.batchSelectionTarget.style.display = "block"
    this.submitBtnTarget.style.display = "block"
  }

  hideAllSections() {
    this.productSelectionTarget.style.display = "none"
    this.hideDependentSections()
  }

  hideDependentSections() {
    this.quantityFieldTarget.style.display = "none"
    this.batchSelectionTarget.style.display = "none"
    this.submitBtnTarget.style.display = "none"
  }

  disconnect() {
    // Clean up event listeners
    this.locationSelect?.removeEventListener('change', this.handleLocationChange)
    this.productSelectTarget?.removeEventListener('change', this.handleProductChange)
  }
}