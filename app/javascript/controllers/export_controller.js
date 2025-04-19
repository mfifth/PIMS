// app/javascript/controllers/export_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["exportButton"]
  
  connect() {
    this.updateExportUrl()
    document.addEventListener('turbo:load', this.updateExportUrl.bind(this))
  }

  disconnect() {
    document.removeEventListener('turbo:load', this.updateExportUrl.bind(this))
  }

  // export_controller.js
  updateExportUrl() {
    if (!this.hasExportButtonTarget) return
    
    const currentUrl = new URL(window.location.href)
    const exportUrl = new URL(this.exportButtonTarget.href.split('?')[0], window.location.origin)
    
    if (currentUrl.searchParams.has('perishable')) {
      exportUrl.searchParams.set('perishable', currentUrl.searchParams.get('perishable'))
    }
    if (currentUrl.searchParams.has('low_stock')) {
      exportUrl.searchParams.set('low_stock', currentUrl.searchParams.get('low_stock'))
    }
    if (currentUrl.searchParams.has('expiring')) {
      exportUrl.searchParams.set('expiring', currentUrl.searchParams.get('expiring'))
    }
    
    this.exportButtonTarget.href = exportUrl.toString()
  }
}