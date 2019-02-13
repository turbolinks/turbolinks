import { Location } from "./location"
import { dispatch } from "./util"

export type StatusCode = number

export enum SystemStatusCode {
  networkFailure = 0,
  timeoutFailure = -1
}

export interface HttpRequestDelegate {
  requestStarted(): void
  requestProgressed(progress: number): void
  requestFinished(): void
  requestCompletedWithResponse(response: string, redirectedToLocation?: Location): void
  requestFailedWithStatusCode(statusCode: StatusCode, response?: string): void
}

export class HttpRequest {
  static timeout = 60

  readonly delegate: HttpRequestDelegate
  readonly location: Location
  readonly referrer?: Location
  readonly url: string

  failed = false
  progress = 0
  sent = false
  xhr?: XMLHttpRequest

  constructor(delegate: HttpRequestDelegate, location: Location, referrer?: Location) {
    this.delegate = delegate
    this.location = location
    this.referrer = referrer
    this.location = Location.wrap(location)
    this.referrer = Location.wrap(referrer)
    this.url = location.absoluteURL
    this.createXHR()
  }

  send() {
    if (this.xhr && !this.sent) {
      this.notifyApplicationBeforeRequestStart()
      this.setProgress(0)
      this.xhr.send()
      this.sent = true
      this.delegate.requestStarted()
    }
  }

  cancel() {
    if (this.xhr && this.sent) {
      this.xhr.abort()
    }
  }

  // XMLHttpRequest events

  requestProgressed = (event: ProgressEvent) => {
    if (event.lengthComputable) {
      this.setProgress(event.loaded / event.total)
    }
  }

  requestLoaded = () => {
    this.endRequest(xhr => {
      if (xhr.status >= 200 && xhr.status < 300) {
        const redirectedToLocation = Location.wrap(xhr.getResponseHeader("Turbolinks-Location") )
        this.delegate.requestCompletedWithResponse(xhr.responseText, redirectedToLocation)
      } else {
        this.failed = true
        this.delegate.requestFailedWithStatusCode(xhr.status, xhr.responseText)
      }
    })
  }

  requestFailed = () => {
    this.endRequest(() => {
      this.failed = true
      this.delegate.requestFailedWithStatusCode(SystemStatusCode.networkFailure)
    })
  }

  requestTimedOut = () => {
    this.endRequest(() => {
      this.failed = true
      this.delegate.requestFailedWithStatusCode(SystemStatusCode.timeoutFailure)
    })
  }

  requestCanceled = () => {
    this.endRequest()
  }

  // Application events

  notifyApplicationBeforeRequestStart() {
    dispatch("turbolinks:request-start", { data: { url: this.url, xhr: this.xhr } })
  }

  notifyApplicationAfterRequestEnd() {
    dispatch("turbolinks:request-end", { data: { url: this.url, xhr: this.xhr } })
  }

  // Private

  createXHR() {
    const xhr = this.xhr = new XMLHttpRequest
    const referrer = this.referrer ? this.referrer.absoluteURL : ""
    const timeout = HttpRequest.timeout * 1000

    xhr.open("GET", this.url, true)
    xhr.timeout = timeout
    xhr.setRequestHeader("Accept", "text/html, application/xhtml+xml")
    xhr.setRequestHeader("Turbolinks-Referrer", referrer)
    xhr.onprogress = this.requestProgressed
    xhr.onload = this.requestLoaded
    xhr.onerror = this.requestFailed
    xhr.ontimeout = this.requestTimedOut
    xhr.onabort = this.requestCanceled
  }

  endRequest(callback: (xhr: XMLHttpRequest) => void = () => {}) {
    if (this.xhr) {
      this.notifyApplicationAfterRequestEnd()
      callback(this.xhr)
      this.destroy()
    }
  }

  setProgress(progress: number) {
    this.progress = progress
    this.delegate.requestProgressed(progress)
  }

  destroy() {
    this.setProgress(1)
    this.delegate.requestFinished()
  }
}
