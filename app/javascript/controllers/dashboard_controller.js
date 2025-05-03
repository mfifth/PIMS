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
    
    const { scrollTop, scrollHeight, clientHeight } = container
    const threshold = 100
    const distanceToBottom = scrollHeight - (scrollTop + clientHeight)
  
    if (distanceToBottom <= threshold) {
      this.loadMore(container)
    }
  }

  loadMore(container) {
    const nextPageLink = container.querySelector(".hidden a[rel='next']")
    if (!nextPageLink) {
      console.log('No more pages to load')
      return
    }
  
    // Prevent duplicate requests
    if (nextPageLink.dataset.loading === 'true') return
    nextPageLink.dataset.loading = 'true'
  
    fetch(nextPageLink.href, {
      headers: { 
        Accept: "text/vnd.turbo-stream.html",
        "X-Custom-Request-Type": "InfiniteScroll"
      }
    })
    .then(response => {
      if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`)
      return response.text()
    })
    .then(html => {
      if (!html.includes('turbo-stream')) {
        throw new Error('Invalid Turbo Stream response')
      }
      Turbo.renderStreamMessage(html)
    })
    .catch(error => {
      console.error('Infinite scroll error:', error)
      // Re-enable loading on error
      nextPageLink.dataset.loading = 'false'
    })
    .finally(() => {
      this.loadingValue = false
      // Manually re-check scroll position after load
      setTimeout(() => this.handleScroll(container), 100)
    })
  }
}