import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="scroll-effects"
export default class extends Controller {
  static targets = ["nav"]

  connect() {
    this.setupScrollEffects()
    this.setupSmoothScroll()
  }

  setupScrollEffects() {
    let lastScroll = 0
    
    window.addEventListener("scroll", () => {
      const currentScroll = window.pageYOffset
      
      if (this.hasNavTarget) {
        // Add shadow on scroll
        if (currentScroll > 10) {
          this.navTarget.style.boxShadow = "0 10px 30px rgba(4, 10, 28, 0.3)"
          this.navTarget.style.background = "linear-gradient(120deg, rgba(6, 12, 28, 0.95), rgba(6, 12, 28, 0.85))"
        } else {
          this.navTarget.style.boxShadow = "0 10px 25px rgba(4, 10, 28, 0.18)"
          this.navTarget.style.background = "linear-gradient(120deg, rgba(6, 12, 28, 0.82), rgba(6, 12, 28, 0.65))"
        }
        
        // Hide/show nav on scroll
        if (currentScroll > lastScroll && currentScroll > 100) {
          this.navTarget.style.transform = "translateY(-100%)"
        } else {
          this.navTarget.style.transform = "translateY(0)"
        }
      }
      
      lastScroll = currentScroll
    })
  }

  setupSmoothScroll() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
      anchor.addEventListener("click", (e) => {
        const href = anchor.getAttribute("href")
        if (href === "#") return
        
        e.preventDefault()
        const target = document.querySelector(href)
        
        if (target) {
          target.scrollIntoView({
            behavior: "smooth",
            block: "start"
          })
        }
      })
    })
  }

  // Reveal elements on scroll
  revealOnScroll() {
    const reveals = document.querySelectorAll("[data-reveal]")
    
    reveals.forEach(element => {
      const windowHeight = window.innerHeight
      const elementTop = element.getBoundingClientRect().top
      const elementVisible = 150
      
      if (elementTop < windowHeight - elementVisible) {
        element.classList.add("revealed")
      }
    })
  }
}
