import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="theme"
export default class extends Controller {
  static targets = ["toggle"]

  connect() {
    this.loadTheme()
    this.setupThemeTransition()
  }

  loadTheme() {
    const savedTheme = localStorage.getItem("theme")
    if (savedTheme) {
      document.documentElement.setAttribute("data-theme", savedTheme)
    }
  }

  toggle() {
    const currentTheme = document.documentElement.getAttribute("data-theme")
    const newTheme = currentTheme === "light" ? "dark" : "light"
    
    // Add transition class
    document.documentElement.classList.add("theme-transitioning")
    
    // Change theme
    document.documentElement.setAttribute("data-theme", newTheme)
    localStorage.setItem("theme", newTheme)
    
    // Remove transition class after animation
    setTimeout(() => {
      document.documentElement.classList.remove("theme-transitioning")
    }, 300)
  }

  setupThemeTransition() {
    // Smooth theme transitions
    const style = document.createElement("style")
    style.textContent = `
      .theme-transitioning,
      .theme-transitioning *,
      .theme-transitioning *::before,
      .theme-transitioning *::after {
        transition: background-color 0.3s ease, color 0.3s ease, border-color 0.3s ease !important;
      }
    `
    document.head.appendChild(style)
  }
}
