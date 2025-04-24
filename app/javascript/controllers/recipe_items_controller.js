import { Controller } from "@hotwired/stimulus"
import debounce from "lodash.debounce"

export default class extends Controller {
  static targets = ["items", "template", "searchInput", "searchResults"]
  static values = { unitMap: Object }

  connect() {
    const rawMap = this.element.dataset.unitMap
    this.unitMap = rawMap ? JSON.parse(rawMap) : {}
    this.search = debounce(this._search.bind(this), 300)
  }

  _search() {
    const query = this.searchInputTarget.value.trim()
  
    if (query.length < 2) {
      this.clearResults()
      return
    }
  
    this.searchResultsTarget.classList.remove('hidden')
  
    const selectedIds = Array.from(this.itemsTarget.querySelectorAll('input[name*="[product_id]"]'))
      .map(input => input.value)
      .filter(id => id)
  
    const params = new URLSearchParams()
    params.append('query', query)
    selectedIds.forEach(id => params.append('selected_ids[]', id))
  
    fetch(`/recipes/product_search?${params.toString()}`, {
      headers: { 
        Accept: "text/vnd.turbo-stream.html",
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
      .then(response => {
        if (!response.ok) throw new Error("Network response was not ok")
        return response.text()
      })
      .then(html => {
        Turbo.renderStreamMessage(html)
        this.searchResultsTarget.classList.remove('hidden')
      })
      .catch(error => {
        console.error("Search error:", error)
        this.clearResults()
      })
  }  

  selectProduct(event) {
    event.preventDefault()
    const productId = event.currentTarget.dataset.productId
    const productName = event.currentTarget.dataset.productName
    const unitType = event.currentTarget.dataset.unitType || 'units'

    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.itemsTarget.insertAdjacentHTML("beforeend", content)

    const newItem = this.itemsTarget.lastElementChild
    const productNameElement = newItem.querySelector('[data-recipe-items-target="productName"]')
    const unitDisplayElement = newItem.querySelector('[data-recipe-items-target="unitDisplay"]')
    const unitInputElement = newItem.querySelector('[data-recipe-items-target="unitInput"]')
    const unitSelectElement = newItem.querySelector('select[name*="[unit]"]')
    const productIdInput = newItem.querySelector('input[name*="product_id"]')

    if (productNameElement && unitDisplayElement && unitInputElement && productIdInput) {
      productNameElement.textContent = productName
      unitDisplayElement.textContent = unitType
      unitInputElement.value = unitType
      productIdInput.value = productId
    }

    if (unitSelectElement && unitType && this.unitMapValue[unitType]) {
      const options = this.unitMapValue[unitType]
      unitSelectElement.innerHTML = options
        .map(unit => `<option value="${unit}">${unit.charAt(0).toUpperCase() + unit.slice(1)}</option>`)
        .join('')
    }

    this.clearSearch()
  }

  add(event) {
    event.preventDefault()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.itemsTarget.insertAdjacentHTML("beforeend", content)
  }

  remove(event) {
    event.preventDefault()
    const item = event.target.closest(".ingredient-item")
    if (item.dataset.newRecord === "true") {
      item.remove()
    } else {
      item.querySelector("input[name*='_destroy']").value = "1"
      item.style.display = "none"
    }
  }

  clearSearch() {
    this.searchInputTarget.value = ""
    this.clearResults()
  }

  clearResults() {
    if (this.hasSearchResultsTarget) {
      this.searchResultsTarget.innerHTML = ""
      this.searchResultsTarget.classList.add('hidden')
    }
  }
}
