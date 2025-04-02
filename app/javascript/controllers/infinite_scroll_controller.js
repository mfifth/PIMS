import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";

export default class extends Controller {
  static values = { url: String };

  connect() {
    this.observer = new IntersectionObserver(entries => {
      if (entries[0].isIntersecting) {
        this.loadMore();
      }
    });

    this.observer.observe(this.element);
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect();
    }
  }

  loadMore() {
    if (this.urlValue) {
      fetch(this.urlValue)
      .then(response => response.text())
      .then(html => Turbo.renderStreamMessage(html))
      .catch(error => console.error("Infinite scroll error:", error));
    }
  }
}
