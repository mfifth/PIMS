import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["entries", "pagination", "scrollContainer"]
  static values = { loading: Boolean }

  connect() {
    console.log("Dashboard controller connected to:", this.element)
    this.scrollContainers = this.scrollContainerTargets
    this.scrollHandlers = []
    
    this.scrollContainers.forEach(container => {
      const handler = this.handleScroll.bind(this, container)
      this.scrollHandlers.push(handler)
      container.addEventListener('scroll', handler)
      console.log(`Added scroll listener to:`, container)
    })
  }

  disconnect() {
    this.scrollContainers.forEach((container, index) => {
      container.removeEventListener('scroll', this.scrollHandlers[index])
    })
  }

  handleScroll(container) {
    if (this.loadingValue) {
      console.log("Already loading, skipping")
      return
    }

    const scrollPosition = container.scrollTop + container.clientHeight
    const scrollHeight = container.scrollHeight
    const threshold = 50 // pixels from bottom

    console.log(`Scroll container: ${container.id}`)
    console.log(`Position: ${scrollPosition}, Height: ${scrollHeight}, Threshold: ${scrollHeight - threshold}`)

    if (scrollPosition >= (scrollHeight - threshold)) {
      console.log("Bottom reached for container:", container.id)
      this.loadMore(container)
    }
  }

  loadMore(container) {
    const pagination = container.querySelector("[data-dashboard-target='pagination']")
    const nextPage = pagination?.querySelector("a[rel='next']")
    
    if (!nextPage) {
      console.log("No more pages to load for container:", container.id)
      return
    }

    console.log("Loading next page for container:", container.id, "URL:", nextPage.href)
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
      console.log("Received response for container:", container.id)
      Turbo.renderStreamMessage(html)
    })
    .catch(error => console.error("Error loading more items:", error))
    .finally(() => {
      this.loadingValue = false
      console.log("Loading complete for container:", container.id)
    })
  }
}