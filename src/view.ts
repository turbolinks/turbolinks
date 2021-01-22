import { ErrorRenderer } from "./error_renderer"
import { Location } from "./location"
import { Snapshot } from "./snapshot"
import { RenderCallback, RenderDelegate, SnapshotRenderer } from "./snapshot_renderer"
import { RootSelector } from "./root_selector"

export type RenderOptions = { snapshot: Snapshot, error: string, isPreview: boolean, rootSelector: RootSelector }

export class View {
  readonly delegate: RenderDelegate
  readonly htmlElement = document.documentElement as HTMLHtmlElement

  constructor(delegate: RenderDelegate) {
    this.delegate = delegate
  }

  getRootLocation(): Location {
    return this.getSnapshot().getRootLocation()
  }

  getElementForAnchor(anchor: string) {
    return this.getSnapshot().getElementForAnchor(anchor)
  }

  getSnapshot(): Snapshot {
    return Snapshot.fromHTMLElement(this.htmlElement)
  }

  render({ snapshot, error, isPreview, rootSelector}: Partial<RenderOptions>, callback: RenderCallback) {
    this.markAsPreview(isPreview)
    if (snapshot) {
      this.renderSnapshot(snapshot, isPreview, callback, rootSelector)
    } else {
      this.renderError(error, callback)
    }
  }

  // Private

  markAsPreview(isPreview: boolean | undefined) {
    if (isPreview) {
      this.htmlElement.setAttribute("data-turbolinks-preview", "")
    } else {
      this.htmlElement.removeAttribute("data-turbolinks-preview")
    }
  }

  renderSnapshot(snapshot: Snapshot, isPreview: boolean | undefined, callback: RenderCallback, rootSelector: RootSelector) {
    SnapshotRenderer.render(this.delegate, callback, this.getSnapshot(), snapshot, isPreview || false, rootSelector)
  }

  renderError(error: string | undefined, callback: RenderCallback) {
    ErrorRenderer.render(this.delegate, callback, error || "")
  }
}
