import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="animations"
export default class extends Controller {
  static targets = ["card", "copyable", "submit"]

  connect() {
    this.setupIntersectionObserver()
    this.setupCopyToClipboard()
    this.setupParallaxEffect()
  }

  setupIntersectionObserver() {
    const options = {
      threshold: 0.1,
      rootMargin: "0px 0px -100px 0px"
    }

    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.style.opacity = "1"
          entry.target.style.transform = "translateY(0)"
        }
      })
    }, options)

    // Observe all cards
    this.cardTargets.forEach(card => {
      card.style.opacity = "0"
      card.style.transform = "translateY(30px)"
      card.style.transition = "opacity 0.6s ease, transform 0.6s ease"
      observer.observe(card)
    })
  }

  setupCopyToClipboard() {
    this.copyableTargets.forEach(element => {
      element.addEventListener("click", async (e) => {
        const text = element.textContent.trim()
        
        try {
          await navigator.clipboard.writeText(text)
          this.showCopyFeedback(element)
        } catch (err) {
          console.error("Failed to copy:", err)
        }
      })
    })
  }

  showCopyFeedback(element) {
    const originalBg = element.style.background
    element.style.background = "rgba(43, 255, 132, 0.15)"
    
    // Create checkmark indicator
    const checkmark = document.createElement("span")
    checkmark.textContent = "✓ Copied"
    checkmark.style.cssText = `
      position: absolute;
      top: 50%;
      right: 1rem;
      transform: translateY(-50%);
      color: var(--success);
      font-size: 0.85rem;
      font-weight: 600;
      animation: fade-in-up 0.3s ease;
    `
    
    element.style.position = "relative"
    element.appendChild(checkmark)
    
    setTimeout(() => {
      element.style.background = originalBg
      checkmark.remove()
    }, 2000)
  }

  setupParallaxEffect() {
    let ticking = false
    
    window.addEventListener("scroll", () => {
      if (!ticking) {
        window.requestAnimationFrame(() => {
          this.updateParallax()
          ticking = false
        })
        ticking = true
      }
    })
  }

  updateParallax() {
    const scrolled = window.pageYOffset
    const cards = document.querySelectorAll(".calculator__card")
    
    cards.forEach((card, index) => {
      const speed = 0.05 * (index + 1)
      const yPos = -(scrolled * speed)
      card.style.transform = `translateY(${yPos}px)`
    })
  }

  // Ripple effect on button click
  ripple(event) {
    const button = event.currentTarget
    const rect = button.getBoundingClientRect()
    const size = Math.max(rect.width, rect.height)
    const x = event.clientX - rect.left - size / 2
    const y = event.clientY - rect.top - size / 2
    
    const ripple = document.createElement("span")
    ripple.style.cssText = `
      position: absolute;
      width: ${size}px;
      height: ${size}px;
      left: ${x}px;
      top: ${y}px;
      background: rgba(255, 255, 255, 0.5);
      border-radius: 50%;
      transform: scale(0);
      animation: ripple-effect 0.6s ease-out;
      pointer-events: none;
    `
    
    button.appendChild(ripple)
    
    setTimeout(() => ripple.remove(), 600)
  }

  // Add loading state to submit button
  submitForm(event) {
    const button = event.currentTarget
    const originalText = button.textContent
    
    button.disabled = true
    button.innerHTML = `
      <span class="loading-spinner"></span>
      <span style="margin-left: 0.5rem;">Processing...</span>
    `
    
    // Form will submit naturally, but we show loading state
    setTimeout(() => {
      button.disabled = false
      button.textContent = originalText
    }, 3000)
  }
}
