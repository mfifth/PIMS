import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["entries", "pagination"]
  static values = { loading: Boolean }

  connect() {
    this.scrollContainers = this.element.querySelectorAll(".scroll-container")
    this.scrollHandlers = []
    this.lastScrollTime = 0
    
    this.scrollContainers.forEach(container => {
      const handler = () => this.handleScroll(container)
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
    if (this.loadingValue) return
    
    // Throttle scroll events
    const now = Date.now()
    if (now - this.lastScrollTime < 500) return
    this.lastScrollTime = now

    const { scrollTop, scrollHeight, clientHeight } = container
    const threshold = 500  // Increased threshold
    const distanceToBottom = scrollHeight - (scrollTop + clientHeight)

    if (distanceToBottom <= threshold) {
      this.loadMore(container)
    }
  }

  loadMore(container) {
    const nextPageLink = container.querySelector(".hidden a[rel='next']")
    if (!nextPageLink) return

    this.loadingValue = true
    
    fetch(nextPageLink.href, {
      headers: { 
        Accept: "text/vnd.turbo-stream.html",
        "X-Custom-Request-Type": "InfiniteScroll"
      }
    })
    .then(response => {
      if (!response.ok) throw new Error("Network response was not ok")
      return response.text()
    })
    .then(html => Turbo.renderStreamMessage(html))
    .catch(error => console.error("Error loading more items:", error))
    .finally(() => {
      this.loadingValue = false
      this.lastScrollTime = Date.now() // Reset timer after load
    })
  }
}