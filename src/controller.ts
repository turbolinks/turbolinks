import { Adapter } from "./adapter"
import { BrowserAdapter } from "./browser_adapter"
import { History } from "./history"
import { Location, Locatable } from "./location"
import { RenderCallback } from "./renderer"
import { ScrollManager } from "./scroll_manager"
import { SnapshotCache } from "./snapshot_cache"
import { Action, Position, isAction } from "./types"
import { closest, defer, dispatch, uuid } from "./util"
import { RenderOptions, View } from "./view"
import { Visit } from "./visit"

export type RestorationData = { scrollPosition?: Position }
export type RestorationDataMap = { [uuid: string]: RestorationData }
export type TimingData = {}
export type VisitOptions = { action: Action }
export type VisitProperties = { restorationIdentifier: string, restorationData: RestorationData, historyChanged: boolean }

export class Controller {
  static supported = !!(
    window.history.pushState &&
    window.requestAnimationFrame &&
    window.addEventListener
  )

  readonly adapter: Adapter = new BrowserAdapter(this)
  readonly history = new History(this)
  readonly restorationData: RestorationDataMap = {}
  readonly scrollManager = new ScrollManager(this)
  readonly view = new View(this)

  cache = new SnapshotCache(10)
  currentVisit?: Visit
  enabled = true
  lastRenderedLocation?: Location
  location!: Location
  progressBarDelay = 500
  restorationIdentifier!: string
  started = false

  start() {
    if (Controller.supported && !this.started) {
      addEventListener("click", this.clickCaptured, true)
      addEventListener("DOMContentLoaded", this.pageLoaded, false)
      this.scrollManager.start()
      this.startHistory()
      this.started = true
      this.enabled = true
    }
  }

  disable() {
    this.enabled = false
  }

  stop() {
    if (this.started) {
      removeEventListener("click", this.clickCaptured, true)
      removeEventListener("DOMContentLoaded", this.pageLoaded, false)
      this.scrollManager.stop()
      this.stopHistory()
      this.started = false
    }
  }

  clearCache() {
    this.cache = new SnapshotCache(10)
  }

  visit(location: Locatable, options: Partial<VisitOptions> = {}) {
    location = Location.wrap(location)
    if (this.applicationAllowsVisitingLocation(location)) {
      if (this.locationIsVisitable(location)) {
        const action = options.action || "advance"
        this.adapter.visitProposedToLocationWithAction(location, action)
      } else {
        window.location.href = location.toString()
      }
    }
  }

  startVisitToLocationWithAction(location: Locatable, action: Action, restorationIdentifier: string) {
    if (Controller.supported) {
      const restorationData = this.getRestorationDataForIdentifier(restorationIdentifier)
      this.startVisit(Location.wrap(location), action, { restorationData })
    } else {
      window.location.href = location.toString()
    }
  }

  setProgressBarDelay(delay: number) {
    this.progressBarDelay = delay
  }

  // History

  startHistory() {
    this.location = Location.currentLocation
    this.restorationIdentifier = uuid()
    this.history.start()
    this.history.replace(this.location, this.restorationIdentifier)
  }

  stopHistory() {
    this.history.stop()
  }

  pushHistoryWithLocationAndRestorationIdentifier(locatable: Locatable, restorationIdentifier: string) {
    this.location = Location.wrap(locatable)
    this.restorationIdentifier = restorationIdentifier
    this.history.push(this.location, this.restorationIdentifier)
  }

  replaceHistoryWithLocationAndRestorationIdentifier(locatable: Locatable, restorationIdentifier: string) {
    this.location = Location.wrap(locatable)
    this.restorationIdentifier = restorationIdentifier
    this.history.replace(this.location, this.restorationIdentifier)
  }

  // History delegate

  historyPoppedToLocationWithRestorationIdentifier(location: Location, restorationIdentifier: string) {
    if (this.enabled) {
      this.location = location
      this.restorationIdentifier = restorationIdentifier
      const restorationData = this.getRestorationDataForIdentifier(restorationIdentifier)
      this.startVisit(location, "restore", { restorationIdentifier, restorationData, historyChanged: true })
    } else {
      this.adapter.pageInvalidated()
    }
  }

  // Snapshot cache

  getCachedSnapshotForLocation(location: Location) {
    const snapshot = this.cache.get(location)
    return snapshot ? snapshot.clone() : snapshot
  }

  shouldCacheSnapshot() {
    return this.view.getSnapshot().isCacheable()
  }

  cacheSnapshot() {
    if (this.shouldCacheSnapshot()) {
      this.notifyApplicationBeforeCachingSnapshot()
      const snapshot = this.view.getSnapshot()
      const location = this.lastRenderedLocation || Location.currentLocation
      defer(() => this.cache.put(location, snapshot.clone()))
    }
  }

  // Scrolling

  scrollToAnchor(anchor: string) {
    const element = this.view.getElementForAnchor(anchor)
    if (element) {
      this.scrollToElement(element)
    } else {
      this.scrollToPosition({ x: 0, y: 0 })
    }
  }

  scrollToElement(element: Element) {
    this.scrollManager.scrollToElement(element)
  }

  scrollToPosition(position: Position) {
    this.scrollManager.scrollToPosition(position)
  }

  // Scroll manager delegate

  scrollPositionChanged(position: Position) {
    const restorationData = this.getCurrentRestorationData()
    restorationData.scrollPosition = position
  }

  // View

  render(options: Partial<RenderOptions>, callback: RenderCallback) {
    this.view.render(options, callback)
  }

  viewInvalidated() {
    this.adapter.pageInvalidated()
  }

  viewWillRender(newBody: HTMLBodyElement) {
    this.notifyApplicationBeforeRender(newBody)
  }

  viewRendered() {
    this.lastRenderedLocation = this.currentVisit!.location
    this.notifyApplicationAfterRender()
  }

  // Event handlers

  pageLoaded = () => {
    this.lastRenderedLocation = this.location
    this.notifyApplicationAfterPageLoad()
  }

  clickCaptured = () => {
    removeEventListener("click", this.clickBubbled, false)
    addEventListener("click", this.clickBubbled, false)
  }

  clickBubbled = (event: MouseEvent) => {
    if (this.enabled && this.clickEventIsSignificant(event)) {
      const link = this.getVisitableLinkForTarget(event.target)
      if (link) {
        const location = this.getVisitableLocationForLink(link)
        if (location && this.applicationAllowsFollowingLinkToLocation(link, location)) {
          event.preventDefault()
          const action = this.getActionForLink(link)
          this.visit(location, { action })
        }
      }
    }
  }

  // Application events

  applicationAllowsFollowingLinkToLocation(link: Element, location: Location) {
    const event = this.notifyApplicationAfterClickingLinkToLocation(link, location)
    return !event.defaultPrevented
  }

  applicationAllowsVisitingLocation(location: Location) {
    const event = this.notifyApplicationBeforeVisitingLocation(location)
    return !event.defaultPrevented
  }

  notifyApplicationAfterClickingLinkToLocation(link: Element, location: Location) {
    return dispatch("turbolinks:click", { target: link, data: { url: location.absoluteURL }, cancelable: true })
  }

  notifyApplicationBeforeVisitingLocation(location: Location) {
    return dispatch("turbolinks:before-visit", { data: { url: location.absoluteURL }, cancelable: true })
  }

  notifyApplicationAfterVisitingLocation(location: Location) {
    return dispatch("turbolinks:visit", { data: { url: location.absoluteURL } })
  }

  notifyApplicationBeforeCachingSnapshot() {
    return dispatch("turbolinks:before-cache")
  }

  notifyApplicationBeforeRender(newBody: HTMLBodyElement) {
    return dispatch("turbolinks:before-render", { data: { newBody }})
  }

  notifyApplicationAfterRender() {
    return dispatch("turbolinks:render")
  }

  notifyApplicationAfterPageLoad(timing: TimingData = {}) {
    return dispatch("turbolinks:load", { data: { url: this.location.absoluteURL, timing }})
  }

  // Private

  startVisit(location: Location, action: Action, properties: Partial<VisitProperties>) {
    if (this.currentVisit) {
      this.currentVisit.cancel()
    }
    this.currentVisit = this.createVisit(location, action, properties)
    this.currentVisit.start()
    this.notifyApplicationAfterVisitingLocation(location)
  }

  createVisit(location: Location, action: Action, properties: Partial<VisitProperties>): Visit {
    const visit = new Visit(this, location, action, properties.restorationIdentifier)
    visit.restorationData = { ...(properties.restorationData || {}) }
    visit.historyChanged = !!properties.historyChanged
    visit.referrer = this.location
    return visit
  }

  visitCompleted(visit: Visit) {
    this.notifyApplicationAfterPageLoad(visit.getTimingMetrics())
  }

  clickEventIsSignificant(event: MouseEvent) {
    return !(
      (event.target && (event.target as any).isContentEditable)
      || event.defaultPrevented
      || event.which > 1
      || event.altKey
      || event.ctrlKey
      || event.metaKey
      || event.shiftKey
    )
  }

  getVisitableLinkForTarget(target: EventTarget | null) {
    if (target instanceof Element && this.elementIsVisitable(target)) {
      return closest(target, "a[href]:not([target]):not([download])")
    }
  }

  getVisitableLocationForLink(link: Element) {
    const location = new Location(link.getAttribute("href") || "")
    if (this.locationIsVisitable(location)) {
      return location
    }
  }

  getActionForLink(link: Element): Action {
    const action = link.getAttribute("data-turbolinks-action")
    return isAction(action) ? action : "advance"
  }

  elementIsVisitable(element: Element) {
    const container = closest(element, "[data-turbolinks]")
    if (container) {
      return container.getAttribute("data-turbolinks") != "false"
    } else {
      return true
    }
  }

  locationIsVisitable(location: Location) {
    return location.isPrefixedBy(this.view.getRootLocation()) && location.isHTML()
  }

  getCurrentRestorationData(): RestorationData {
    return this.getRestorationDataForIdentifier(this.restorationIdentifier)
  }

  getRestorationDataForIdentifier(identifier: string): RestorationData {
    if (!(identifier in this.restorationData)) {
      this.restorationData[identifier] = {}
    }
    return this.restorationData[identifier]
  }
}
