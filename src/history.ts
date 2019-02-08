import { Location } from "./location"
import { defer } from "./util"

export interface HistoryDelegate {
  historyPoppedToLocationWithRestorationIdentifier(location: Location, restorationIdentifier: string): void
}

type HistoryMethod = (state: any, title: string, url?: string | null | undefined) => void

export class History {
  readonly delegate: HistoryDelegate
  started = false
  pageLoaded = false

  constructor(delegate: HistoryDelegate) {
    this.delegate = delegate
  }

  start() {
    if (!this.started) {
      addEventListener("popstate", this.onPopState, false)
      addEventListener("load", this.onPageLoad, false)
      this.started = true
    }
  }

  stop() {
    if (this.started) {
      removeEventListener("popstate", this.onPopState, false)
      removeEventListener("load", this.onPageLoad, false)
      this.started = false
    }
  }

  push(location: Location, restorationIdentifier: string) {
    this.update(history.pushState, location, restorationIdentifier)
  }

  replace(location: Location, restorationIdentifier: string) {
    this.update(history.replaceState, location, restorationIdentifier)
  }

  // Event handlers

  onPopState = (event: PopStateEvent) => {
    if (this.shouldHandlePopState()) {
      const { turbolinks } = event.state
      if (turbolinks) {
        const location = Location.wrap(window.location.toString())
        const { restorationIdentifier } = turbolinks
        this.delegate.historyPoppedToLocationWithRestorationIdentifier(location, restorationIdentifier)
      }
    }
  }

  onPageLoad = (event: Event) => {
    defer(() => {
      this.pageLoaded = true
    })
  }

  // Private

  shouldHandlePopState() {
    // Safari dispatches a popstate event after window's load event, ignore it
    return this.pageIsLoaded()
  }

  pageIsLoaded() {
    return this.pageLoaded || document.readyState == "complete"
  }

  update(method: HistoryMethod, location: Location, restorationIdentifier: string) {
    const state = { turbolinks: { restorationIdentifier } }
    method.call(history, state, "", location.absoluteURL)
  }
}
