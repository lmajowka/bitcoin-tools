import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="utilities"
export default class extends Controller {
  connect() {
    this.addKeyboardShortcuts()
    this.enhanceAccessibility()
  }

  addKeyboardShortcuts() {
    document.addEventListener("keydown", (e) => {
      // Ctrl/Cmd + K to focus search/input
      if ((e.ctrlKey || e.metaKey) && e.key === "k") {
        e.preventDefault()
        const input = document.querySelector(".calculator__textarea")
        if (input) {
          input.focus()
          input.select()
        }
      }

      // Escape to clear focus
      if (e.key === "Escape") {
        document.activeElement?.blur()
      }
    })
  }

  enhanceAccessibility() {
    // Add skip to main content link
    const skipLink = document.createElement("a")
    skipLink.href = "#main-content"
    skipLink.textContent = "Skip to main content"
    skipLink.className = "skip-link"
    skipLink.style.cssText = `
      position: absolute;
      top: -40px;
      left: 0;
      background: var(--accent);
      color: #000;
      padding: 0.5rem 1rem;
      text-decoration: none;
      z-index: 100;
      transition: top 0.2s ease;
    `
    
    skipLink.addEventListener("focus", () => {
      skipLink.style.top = "0"
    })
    
    skipLink.addEventListener("blur", () => {
      skipLink.style.top = "-40px"
    })
    
    document.body.insertBefore(skipLink, document.body.firstChild)
    
    // Mark main content
    const main = document.querySelector("main")
    if (main) {
      main.id = "main-content"
      main.setAttribute("tabindex", "-1")
    }
  }

  // Copy text to clipboard with visual feedback
  async copyText(event) {
    const text = event.currentTarget.dataset.copyText || event.currentTarget.textContent
    
    try {
      await navigator.clipboard.writeText(text.trim())
      this.showToast("Copied to clipboard!", "success")
    } catch (err) {
      this.showToast("Failed to copy", "error")
    }
  }

  showToast(message, type = "info") {
    const toast = document.createElement("div")
    toast.className = `toast toast--${type}`
    toast.textContent = message
    toast.style.cssText = `
      position: fixed;
      bottom: 2rem;
      right: 2rem;
      background: ${type === "success" ? "var(--success)" : "var(--danger)"};
      color: #000;
      padding: 1rem 1.5rem;
      border-radius: var(--radius-md);
      font-weight: 600;
      box-shadow: var(--shadow);
      z-index: 1000;
      animation: toast-slide-in 0.3s ease;
    `
    
    document.body.appendChild(toast)
    
    setTimeout(() => {
      toast.style.animation = "toast-slide-out 0.3s ease"
      setTimeout(() => toast.remove(), 300)
    }, 3000)
  }
}
