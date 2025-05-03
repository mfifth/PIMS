import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["pagination"]
  static values = { loading: Boolean }

  connect() {
    this.scrollContainers = this.element.querySelectorAll(".scroll-container")
    this.scrollHandlers = []
    this.lastScrollTimes = {}
    this.activeRequests = new Set() // Track active requests

    this.scrollContainers.forEach(container => {
      const handler = () => this.handleScroll(container)
      this.scrollHandlers.push(handler)
      container.addEventListener('scroll', handler)
      this.lastScrollTimes[container.id] = 0
    })
  }

  disconnect() {
    this.scrollContainers.forEach((container, index) => {
      container.removeEventListener('scroll', this.scrollHandlers[index])
    })
    // Abort any pending requests
    this.activeRequests.forEach(controller => controller.abort())
  }

  handleScroll(container) {
    if (this.loadingValue || this.activeRequests.size > 0) return

    const now = Date.now()
    if (now - this.lastScrollTimes[container.id] < 500) return
    this.lastScrollTimes[container.id] = now

    const { scrollTop, scrollHeight, clientHeight } = container
    const distanceToBottom = scrollHeight - (scrollTop + clientHeight)

    if (distanceToBottom <= 300) {
      this.loadMore(container)
    }
  }

  loadMore(container) {
    const cardType = container.id.replace('-scroll-container', '')
    const nextPageLink = container.querySelector(`#${cardType}-pagination a[rel='next']`)
    
    if (!nextPageLink) return

    const controller = new AbortController()
    this.activeRequests.add(controller)
    this.loadingValue = true

    fetch(nextPageLink.href, {
      headers: {
        Accept: "text/vnd.turbo-stream.html",
        "X-Custom-Request-Type": "InfiniteScroll"
      },
      signal: controller.signal
    })
    .then(response => {
      if (!response.ok) throw new Error("Network response was not ok")
      return response.text()
    })
    .then(html => Turbo.renderStreamMessage(html))
    .catch(error => {
      if (error.name !== 'AbortError') {
        console.error("Error loading more items:", error)
      }
    })
    .finally(() => {
      this.activeRequests.delete(controller)
      this.loadingValue = false
      this.lastScrollTimes[container.id] = Date.now()
    })
  }
}