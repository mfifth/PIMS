import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["entries", "pagination", "scrollContainer"]
  static values = { loading: Boolean }

  connect() {
    this.scrollContainers = this.scrollContainerTargets
    this.scrollHandlers = []
    
    this.scrollContainers.forEach(container => {
      const handler = this.handleScroll.bind(this, container)
      this.scrollHandlers.push(handler)
      container.addEventListener('scroll', handler)
    })
  }

  disconnect() {
    this.scrollContainers.forEach((container, index) => {
      container.removeEventListener('scroll', this.scrollHandlers[index])
    })
  }

  handleScroll(container) {
    if (this.loadingValue) {
      return
    }

    const scrollPosition = container.scrollTop + container.clientHeight
    const scrollHeight = container.scrollHeight
    const threshold = 50 // pixels from bottom

    if (scrollPosition >= (scrollHeight - threshold)) {
      this.loadMore(container)
    }
  }

  loadMore(container) {
    const pagination = container.querySelector("[data-dashboard-target='pagination']")
    const nextPage = pagination?.querySelector("a[rel='next']")
    
    if (!nextPage) {
      return
    }

    this.loadingValue = true
    
    fetch(nextPage.href, {
      headers: { 
        Accept: "text/vnd.turbo-stream.html",
        "X-Requested-With": "XMLHttpRequest"
      }
    })
    .then(response => {
      if (!response.ok) throw new Error("Network response was not ok")
      return response.text()
    })
    .then(html => {
      Turbo.renderStreamMessage(html)
    })
    .catch(error => console.error("Error loading more items:", error))
    .finally(() => {
      this.loadingValue = false
    })
  }
}