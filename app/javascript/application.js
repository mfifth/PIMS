import "@hotwired/turbo-rails"
import "controllers"

document.addEventListener("turbo:load", function() {
    const flash = document.getElementById("flash");
    if (flash) {
      setTimeout(() => {
        flash.innerHTML = "";
      }, 8000);
    }
});

document.addEventListener('turbo:load', () => {
  if (window.history.scrollRestoration) {
    window.history.scrollRestoration = 'manual'
  }
})