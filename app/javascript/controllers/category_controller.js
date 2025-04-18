import { Controller } from "@hotwired/stimulus"

// Debounce utility to prevent rapid firing of scroll handler
function debounce(fn, delay = 200) {
  let timeout
  return function(...args) {
    clearTimeout(timeout)
    timeout = setTimeout(() => fn.apply(this, args), delay)
  }
}

export default class extends Controller {
  static values = { 
    url: String,
    loadMoreDistance: { type: Number, default: 5 },
    page: { type: Number, default: 2 }
  }

  static targets = ["loader"]

  initialize() {
    this._handleScroll = this._handleScroll.bind(this)
    this.scrollHandler = debounce(this._handleScroll, 200)
    this.isLoading = false
    this.hasMore = true
    this.loadedCategoryIds = new Set() // Track loaded category IDs
  }

  connect() {
    // Initialize with existing category IDs
    this.element.querySelectorAll('[id^="category-"]').forEach(el => {
      const id = el.id.match(/category-(\d+)-/)?.[1]
      if (id) this.loadedCategoryIds.add(id)
    })
    
    this.element.addEventListener('scroll', this.scrollHandler)
  }

  disconnect() {
    this.element.removeEventListener('scroll', this.scrollHandler)
  }

  _handleScroll() {
    if (!this.hasMore || this.isLoading) return

    const container = this.element
    const scrollPosition = container.scrollTop + container.clientHeight
    const scrollHeight = container.scrollHeight
    const distanceFromBottom = scrollHeight - scrollPosition

    if (distanceFromBottom <= this.loadMoreDistanceValue) {
      this._loadMore()
    }
  }

  async _loadMore() {
    if (!this.hasLoaderTarget || this.isLoading || !this.hasMore) return
  
    this.isLoading = true
    this.loaderTarget.classList.remove('hidden')
  
    try {
      const url = new URL(this.urlValue, window.location.origin)
      url.searchParams.set('page', this.pageValue)
  
      const response = await fetch(url.toString(), {
        headers: {
          'Accept': 'text/vnd.turbo-stream.html'
        }
      })
  
      if (response.ok) {
        const html = await response.text()
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, 'text/html')
        const turboStream = doc.querySelector('turbo-stream[action="append"]')
        
        if (turboStream) {
          // Extract new category IDs from the response
          const newCategoryElements = Array.from(doc.querySelectorAll('[id^="category-"]'))
          const newIds = newCategoryElements.map(el => el.id.match(/category-(\d+)-/)?.[1]).filter(Boolean)
          
          // Filter out duplicates
          const uniqueNewElements = newCategoryElements.filter((el, index) => {
            const id = newIds[index]
            return id && !this.loadedCategoryIds.has(id)
          })
          
          if (uniqueNewElements.length > 0) {
            // Only process if we have new unique categories
            Turbo.renderStreamMessage(html)
            
            // Update our loaded IDs set
            newIds.forEach(id => this.loadedCategoryIds.add(id))
            
            this.pageValue++
          } else {
            // No new unique categories - we've reached the end
            this._handleNoMoreContent()
          }
        } else {
          this._handleNoMoreContent()
        }
      }
    } catch (error) {
      console.error('Error loading more categories:', error)
    } finally {
      this.isLoading = false
      if (this.hasLoaderTarget) {
        this.loaderTarget.classList.add('hidden')
      }
    }
  }

  _handleNoMoreContent() {
    this.hasMore = false
    if (this.hasLoaderTarget) {
      this.loaderTarget.outerHTML = '<div class="py-2 text-center text-xs text-gray-500">No more categories</div>'
    }
  }
}