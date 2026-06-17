// Import Phoenix dependencies
import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

class LocalTime extends HTMLElement {
  connectedCallback() {
    const dt = new Date(this.getAttribute('datetime') + 'Z');
    this.textContent = dt.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
  }
}
customElements.define('local-time', LocalTime);

// Initialize Phoenix Channels
let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let Hooks = {}
Hooks.ChatScroll = {
  mounted() { this.el.scrollTop = this.el.scrollHeight },
  updated() { this.el.scrollTop = this.el.scrollHeight }
}
