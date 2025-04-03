import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    container: String,
  }

  connect() {
    this.isLoading = false
    this.hasMorePages = !!this.urlValue  // Check if there's a next page
    window.addEventListener("scroll", this.checkScroll.bind(this))
  }

  checkScroll() {
    if (this.isLoading || !this.hasMorePages) return

    const nearBottom = window.innerHeight + window.scrollY >= document.body.offsetHeight - 200
    if (nearBottom) {
      this.loadNextPage()
    }
  }

  async loadNextPage() {
    if (!this.urlValue) {
      this.hasMorePages = false
      return
    }

    this.isLoading = true
    const loading = document.getElementById("loading")
    if (loading) loading.classList.remove("hidden")

    try {
      const response = await fetch(this.urlValue)
      if (response.ok) {
        const html = await response.text()
        const container = document.querySelector(this.containerValue)

        if (!container) {
          console.error("Batch container not found.")
          this.hasMorePages = false
          return
        }

        if (html.trim() === "") {
          this.hasMorePages = false
        } else {
          container.insertAdjacentHTML("beforeend", html)

          // Get the new next_page from the response
          const parser = new DOMParser()
          const doc = parser.parseFromString(html, "text/html")
          const newUrl = doc.querySelector("[data-infinite-batch-scroll-url-value]")?.dataset.infiniteBatchScrollUrlValue

          if (newUrl) {
            this.urlValue = newUrl
          } else {
            this.hasMorePages = false
          }
        }
      } else {
        console.error("Error loading next page:", response.status)
        this.hasMorePages = false
      }
    } catch (err) {
      console.error("Fetch failed:", err)
    }

    this.isLoading = false
    if (loading) loading.classList.add("hidden")
  }
}
