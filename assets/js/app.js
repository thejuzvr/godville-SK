// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

let Hooks = {}

Hooks.LocalClock = {
  mounted() {
    this.tz = Intl.DateTimeFormat().resolvedOptions().timeZone
    this.render()
    this.timer = setInterval(() => this.render(), 1000)
  },
  updated() {
    this.render()
  },
  destroyed() {
    if (this.timer) clearInterval(this.timer)
  },
  render() {
    const iso = this.el.dataset.utc
    if (!iso) return
    const dt = new Date(iso)
    if (Number.isNaN(dt.getTime())) return

    const dateFmt = new Intl.DateTimeFormat("ru-RU", {
      weekday: "long",
      year: "numeric",
      month: "long",
      day: "numeric",
      timeZone: this.tz
    })

    const timeFmt = new Intl.DateTimeFormat("ru-RU", {
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
      hour12: false,
      timeZone: this.tz
    })

      const dateEl = this.el.querySelector("[data-role='date']")
    const timeEl = this.el.querySelector("[data-role='time']")
    if (dateEl) dateEl.textContent = dateFmt.format(dt)
    if (timeEl) timeEl.textContent = timeFmt.format(dt)
  }
}

Hooks.SovngardeTimer = {
  mounted() {
    this.update()
    this.interval = setInterval(() => this.update(), 1000)
  },
  updated() {
    this.update()
  },
  destroyed() {
    if (this.interval) clearInterval(this.interval)
  },
  update() {
    const respawnAt = this.el.dataset.respawnAt
    if (!respawnAt) return

    const target = new Date(respawnAt)
    const now = new Date()
    const diff = target - now

    if (diff <= 0) {
      this.el.textContent = "ГОТОВ К ВОЗВРАЩЕНИЮ"
      this.el.classList.add("text-primary", "animate-pulse")
      return
    }

    const mins = Math.floor(diff / 60000)
    const secs = Math.floor((diff % 60000) / 1000)
    this.el.textContent = `${String(mins).padStart(2, "0")}:${String(secs).padStart(2, "0")}`
  }
}

import {DiceRollerHook} from "../vendor/d20"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Object.assign(Hooks, {DiceRollerHook})
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

