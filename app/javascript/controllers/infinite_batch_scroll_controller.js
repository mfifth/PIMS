import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    container: String,
  }

  connect() {
    this.isLoading = false
    this.hasMorePages = true
    this.scrollHandler = this.debounce(this.checkScroll.bind(this), 200)
    window.addEventListener("scroll", this.scrollHandler)
  }

  disconnect() {
    window.removeEventListener("scroll", this.scrollHandler)
  }

  checkScroll() {
    if (this.isLoading || !this.hasMorePages) return

    const nearBottom = window.innerHeight + window.scrollY >= document.body.offsetHeight - 200
    if (nearBottom) {
      this.loadNextPage()
    }
  }

  async loadNextPage() {
    const url = this.getNextPageUrl()
    if (!url) {
      this.hasMorePages = false
      return
    }

    this.isLoading = true
    const loading = document.getElementById("loading")
    if (loading) loading.classList.remove("hidden")

    try {
      const response = await fetch(url)
      const html = await response.text()

      const container = document.querySelector(this.containerValue)
      if (!container) {
        console.error("Scroll container not found")
        this.hasMorePages = false
        return
      }

      if (html.trim() === "") {
        this.hasMorePages = false
      } else {
        container.insertAdjacentHTML("beforeend", html)

        // Update next page URL after insert
        const nextUrl = this.getNextPageUrl()
        if (!nextUrl) this.hasMorePages = false
      }
    } catch (err) {
      console.error("Error loading next page:", err)
    }

    this.isLoading = false
    if (loading) loading.classList.add("hidden")
  }

  getNextPageUrl() {
    return document.getElementById("infinite-scroll-metadata")?.dataset.infiniteBatchScrollUrlValue || ""
  }

  debounce(func, delay) {
    let timeout
    return function () {
      clearTimeout(timeout)
      timeout = setTimeout(() => func.apply(this, arguments), delay)
    }
  }
}
