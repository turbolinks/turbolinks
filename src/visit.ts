import { Adapter } from "./adapter"
import { Controller, RestorationData } from "./controller"
import { HttpRequest } from "./http_request"
import { Location } from "./location"
import { RenderCallback } from "./renderer"
import { Snapshot } from "./snapshot"
import { Action } from "./types"
import { uuid } from "./util"

export enum TimingMetric {
  visitStart = "visitStart",
  requestStart = "requestStart",
  requestEnd = "requestEnd",
  visitEnd = "visitEnd"
}

export type TimingMetrics = Partial<{ [metric in TimingMetric]: any }>

export enum VisitState {
  initialized = "initialized",
  started = "started",
  canceled = "canceled",
  failed = "failed",
  completed = "completed"
}

export class Visit {
  readonly controller: Controller
  readonly action: Action
  readonly adapter: Adapter
  readonly identifier = uuid()
  readonly restorationIdentifier: string
  readonly timingMetrics: TimingMetrics = {}

  followedRedirect = false
  frame?: number
  historyChanged = false
  location: Location
  progress = 0
  referrer?: Location
  redirectedToLocation?: Location
  request?: HttpRequest
  response?: string
  restorationData?: RestorationData
  scrolled = false
  snapshotCached = false
  state = VisitState.initialized

  constructor(controller: Controller, location: Location, action: Action, restorationIdentifier: string = uuid()) {
    this.controller = controller
    this.location = location
    this.action = action
    this.adapter = controller.adapter
    this.restorationIdentifier = restorationIdentifier
  }

  start() {
    if (this.state == VisitState.initialized) {
      this.recordTimingMetric(TimingMetric.visitStart)
      this.state = VisitState.started
      this.adapter.visitStarted(this)
    }
  }

  cancel() {
    if (this.state == VisitState.started) {
      if (this.request) {
        this.request.cancel()
      }
      this.cancelRender()
      this.state = VisitState.canceled
    }
  }

  complete() {
    if (this.state == VisitState.started) {
      this.recordTimingMetric(TimingMetric.visitEnd)
      this.state = VisitState.completed
      this.adapter.visitCompleted(this)
      this.controller.visitCompleted(this)
    }
  }

  fail() {
    if (this.state == VisitState.started) {
      this.state = VisitState.failed
      this.adapter.visitFailed(this)
    }
  }

  changeHistory() {
    if (!this.historyChanged) {
      const actionForHistory = this.location.isEqualTo(this.referrer) ? "replace" : this.action
      const method = this.getHistoryMethodForAction(actionForHistory)
      method.call(this.controller, this.location, this.restorationIdentifier)
      this.historyChanged = true
    }
  }

  issueRequest() {
    if (this.shouldIssueRequest() && !this.request) {
      this.progress = 0
      this.request = new HttpRequest(this, this.location, this.referrer)
      this.request.send()
    }
  }

  getCachedSnapshot() {
    const snapshot = this.controller.getCachedSnapshotForLocation(this.location)
    if (snapshot && (!this.location.anchor || snapshot.hasAnchor(this.location.anchor))) {
      if (this.action == "restore" || snapshot.isPreviewable()) {
        return snapshot
      }
    }
  }

  hasCachedSnapshot() {
    return this.getCachedSnapshot() != null
  }

  loadCachedSnapshot() {
    const snapshot = this.getCachedSnapshot()
    if (snapshot) {
      const isPreview = this.shouldIssueRequest()
      this.render(() => {
        this.cacheSnapshot()
        this.controller.render({ snapshot, isPreview }, this.performScroll)
        this.adapter.visitRendered(this)
        if (!isPreview) {
          this.complete()
        }
      })
    }
  }

  loadResponse() {
    const { request, response } = this
    if (request && response) {
      this.render(() => {
        this.cacheSnapshot()
        if (request.failed) {
          this.controller.render({ error: this.response }, this.performScroll)
          this.adapter.visitRendered(this)
          this.fail()
        } else {
          this.controller.render({ snapshot: Snapshot.fromHTMLString(response) }, this.performScroll)
          this.adapter.visitRendered(this)
          this.complete()
        }
      })
    }
  }

  followRedirect() {
    if (this.redirectedToLocation && !this.followedRedirect) {
      this.location = this.redirectedToLocation
      this.controller.replaceHistoryWithLocationAndRestorationIdentifier(this.redirectedToLocation, this.restorationIdentifier)
      this.followedRedirect = true
    }
  }

  // HTTP request delegate

  requestStarted() {
    this.recordTimingMetric(TimingMetric.requestStart)
    this.adapter.visitRequestStarted(this)
  }

  requestProgressed(progress: number) {
    this.progress = progress
    if (this.adapter.visitRequestProgressed) {
      this.adapter.visitRequestProgressed(this)
    }
  }

  requestCompletedWithResponse(response: string, redirectedToLocation?: Location) {
    this.response = response
    this.redirectedToLocation = redirectedToLocation
    this.adapter.visitRequestCompleted(this)
  }

  requestFailedWithStatusCode(statusCode: number, response?: string) {
    this.response = response
    this.adapter.visitRequestFailedWithStatusCode(this, statusCode)
  }

  requestFinished() {
    this.recordTimingMetric(TimingMetric.requestEnd)
    this.adapter.visitRequestFinished(this)
  }

  // Scrolling

  performScroll = () => {
    if (!this.scrolled) {
      if (this.action == "restore") {
        this.scrollToRestoredPosition() || this.scrollToTop()
      } else {
        this.scrollToAnchor() || this.scrollToTop()
      }
      this.scrolled = true
    }
  }

  scrollToRestoredPosition() {
    const position = this.restorationData ? this.restorationData.scrollPosition : undefined
    if (position) {
      this.controller.scrollToPosition(position)
      return true
    }
  }

  scrollToAnchor() {
    if (this.location.anchor != null) {
      this.controller.scrollToAnchor(this.location.anchor)
      return true
    }
  }

  scrollToTop() {
    this.controller.scrollToPosition({ x: 0, y: 0 })
  }

  // Instrumentation

  recordTimingMetric(metric: TimingMetric) {
    this.timingMetrics[metric] = new Date().getTime()
  }

  getTimingMetrics(): TimingMetrics {
    return { ...this.timingMetrics }
  }

  // Private

  getHistoryMethodForAction(action: Action) {
    switch (action) {
      case "replace": return this.controller.replaceHistoryWithLocationAndRestorationIdentifier
      case "advance":
      case "restore": return this.controller.pushHistoryWithLocationAndRestorationIdentifier
    }
  }
    shouldIssueRequest() {
    return this.action == "restore"
      ? !this.hasCachedSnapshot()
      : true
  }

  cacheSnapshot() {
    if (!this.snapshotCached) {
      this.controller.cacheSnapshot()
      this.snapshotCached = true
    }
  }

  render(callback: RenderCallback) {
    this.cancelRender()
    this.frame = requestAnimationFrame(() => {
      delete this.frame
      callback.call(this)
    })
  }

  cancelRender() {
    if (this.frame) {
      cancelAnimationFrame(this.frame)
      delete this.frame
    }
  }
}
