import { ErrorRenderer } from "./error_renderer"
import { Location } from "./location"
import { Snapshot } from "./snapshot"
import { RenderCallback, RenderDelegate, SnapshotRenderer } from "./snapshot_renderer"

export type RenderOptions = { snapshot: Snapshot, error: string, isPreview: boolean }

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

  render({ snapshot, error, isPreview }: Partial<RenderOptions>, callback: RenderCallback) {
    this.markAsPreview(isPreview)
    if (snapshot) {
      this.renderSnapshot(snapshot, isPreview, callback)
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

  renderSnapshot(snapshot: Snapshot, isPreview: boolean | undefined, callback: RenderCallback) {
    SnapshotRenderer.render(this.delegate, callback, this.getSnapshot(), snapshot, isPreview || false)
  }

  renderError(error: string | undefined, callback: RenderCallback) {
    ErrorRenderer.render(this.delegate, callback, error || "")
  }
}
