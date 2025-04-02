import { Application } from "@hotwired/stimulus";

const application = Application.start(); // Start Stimulus

// Optional: Improve debugging experience
application.debug = false; 
window.Stimulus = application; // Make Stimulus available in the browser console

export { application }; // Export so other files can use it
