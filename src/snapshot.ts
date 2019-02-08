import { HeadDetails } from "./head_details"
import { Location } from "./location"
import { array } from "./util"

export class Snapshot {
  static wrap(value: Snapshot | string | HTMLHtmlElement) {
    if (value instanceof this) {
      return value
    } else if (typeof value == "string") {
      return this.fromHTMLString(value)
    } else {
      return this.fromHTMLElement(value)
    }
  }

  static fromHTMLString(html: string) {
    const element = document.createElement("html")
    element.innerHTML = html
    return this.fromHTMLElement(element)
  }

  static fromHTMLElement(htmlElement: HTMLHtmlElement) {
    const headElement = htmlElement.querySelector("head")
    const bodyElement = htmlElement.querySelector("body") || document.createElement("body")
    const headDetails = HeadDetails.fromHeadElement(headElement)
    return new this(headDetails, bodyElement)
  }

  readonly headDetails: HeadDetails
  readonly bodyElement: HTMLBodyElement

  constructor(headDetails: HeadDetails, bodyElement: HTMLBodyElement) {
    this.headDetails = headDetails
    this.bodyElement = bodyElement
  }

  clone(): Snapshot {
    return new Snapshot(this.headDetails, this.bodyElement.cloneNode(true))
  }

  getRootLocation() {
    const root = this.getSetting("root", "/")
    return new Location(root)
  }

  getCacheControlValue() {
    return this.getSetting("cache-control")
  }

  getElementForAnchor(anchor: string) {
    try {
      return this.bodyElement.querySelector(`[id='${anchor}'], a[name='${anchor}']`)
    } catch {
      return null
    }
  }

  getPermanentElements() {
    return array(this.bodyElement.querySelectorAll("[id][data-turbolinks-permanent]"))
  }

  getPermanentElementById(id: string) {
    return this.bodyElement.querySelector(`#${id}[data-turbolinks-permanent]`)
  }

  getPermanentElementsPresentInSnapshot(snapshot: Snapshot) {
    return this.getPermanentElements().filter(({ id }) => snapshot.getPermanentElementById(id))
  }

  findFirstAutofocusableElement() {
    return this.bodyElement.querySelector("[autofocus]")
  }

  hasAnchor(anchor: string) {
    return this.getElementForAnchor(anchor) != null
  }

  isPreviewable() {
    return this.getCacheControlValue() != "no-preview"
  }

  isCacheable() {
    return this.getCacheControlValue() != "no-cache"
  }

  isVisitable() {
    return this.getSetting("visit-control") != "reload"
  }

  // Private

  getSetting(name: string): string | undefined
  getSetting(name: string, defaultValue: string): string
  getSetting(name: string, defaultValue?: string) {
    const value = this.headDetails.getMetaValue(`turbolinks-${name}`)
    return value == null ? defaultValue : value
  }
}
