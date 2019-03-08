import { Adapter } from "./adapter"
import { Controller } from "./controller"
import { SystemStatusCode } from "./http_request"
import { Locatable } from "./location"
import { ProgressBar } from "./progress_bar"
import { Action } from "./types"
import { Visit } from "./visit"
import { uuid } from "./util"

export class BrowserAdapter implements Adapter {
  readonly controller: Controller
  readonly progressBar = new ProgressBar

  progressBarTimeout?: number

  constructor(controller: Controller) {
    this.controller = controller
  }

  visitProposedToLocationWithAction(location: Locatable, action: Action) {
    const restorationIdentifier = uuid()
    this.controller.startVisitToLocationWithAction(location, action, restorationIdentifier)
  }

  visitStarted(visit: Visit) {
    visit.issueRequest()
    visit.changeHistory()
    visit.loadCachedSnapshot()
  }

  visitRequestStarted(visit: Visit) {
    this.progressBar.setValue(0)
    if (visit.hasCachedSnapshot() || visit.action != "restore") {
      this.showProgressBarAfterDelay()
    } else {
      this.showProgressBar()
    }
  }

  visitRequestProgressed(visit: Visit) {
    this.progressBar.setValue(visit.progress)
  }

  visitRequestCompleted(visit: Visit) {
    visit.loadResponse()
  }

  visitRequestFailedWithStatusCode(visit: Visit, statusCode: number) {
    switch (statusCode) {
      case SystemStatusCode.networkFailure:
      case SystemStatusCode.timeoutFailure:
      case SystemStatusCode.contentTypeMismatch:
        return this.reload()
      default:
        return visit.loadResponse()
    }
  }

  visitRequestFinished(visit: Visit) {
    this.hideProgressBar()
  }

  visitCompleted(visit: Visit) {
    visit.followRedirect()
  }

  pageInvalidated() {
    this.reload()
  }

  visitFailed(visit: Visit) {

  }

  visitRendered(visit: Visit) {

  }

  // Private

  showProgressBarAfterDelay() {
    this.progressBarTimeout = window.setTimeout(this.showProgressBar, this.controller.progressBarDelay)
  }

  showProgressBar = () => {
    this.progressBar.show()
  }

  hideProgressBar() {
    this.progressBar.hide()
    if (this.progressBarTimeout != null) {
      window.clearTimeout(this.progressBarTimeout)
      delete this.progressBarTimeout
    }
  }

  reload() {
    window.location.reload()
  }
}
