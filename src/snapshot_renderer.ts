import { HeadDetails } from "./head_details"
import { RenderCallback, RenderDelegate, Renderer } from "./renderer"
import { Snapshot } from "./snapshot"
import { array } from "./util"

export { RenderCallback, RenderDelegate } from "./renderer"

export type PermanentElement = Element & { id: string }

export type Placeholder = { element: Element, permanentElement: PermanentElement }

export class SnapshotRenderer extends Renderer {
  readonly delegate: RenderDelegate
  readonly currentSnapshot: Snapshot
  readonly currentHeadDetails: HeadDetails
  readonly newSnapshot: Snapshot
  readonly newHeadDetails: HeadDetails
  readonly newBody: HTMLBodyElement
  readonly isPreview: boolean

  static render(delegate: RenderDelegate, callback: RenderCallback, currentSnapshot: Snapshot, newSnapshot: Snapshot, isPreview: boolean) {
    return new this(delegate, currentSnapshot, newSnapshot, isPreview).render(callback)
  }

  constructor(delegate: RenderDelegate, currentSnapshot: Snapshot, newSnapshot: Snapshot, isPreview: boolean) {
    super()
    this.delegate = delegate
    this.currentSnapshot = currentSnapshot
    this.currentHeadDetails = currentSnapshot.headDetails
    this.newSnapshot = newSnapshot
    this.newHeadDetails = newSnapshot.headDetails
    this.newBody = newSnapshot.bodyElement
    this.isPreview = isPreview
  }

  render(callback: RenderCallback) {
    if (this.shouldRender()) {
      this.mergeHead()
      this.renderView(() => {
        this.replaceBody()
        if (!this.isPreview) {
          this.focusFirstAutofocusableElement()
        }
        callback()
      })
    } else {
      this.invalidateView()
    }
  }

  mergeHead() {
    this.copyNewHeadStylesheetElements()
    this.copyNewHeadScriptElements()
    this.removeCurrentHeadProvisionalElements()
    this.copyNewHeadProvisionalElements()
  }

  replaceBody() {
    const placeholders = this.relocateCurrentBodyPermanentElements()
    this.activateNewBodyScriptElements()
    this.assignNewBody()
    this.replacePlaceholderElementsWithClonedPermanentElements(placeholders)
  }

  shouldRender() {
    return this.newSnapshot.isVisitable() && this.trackedElementsAreIdentical()
  }

  trackedElementsAreIdentical() {
    return this.currentHeadDetails.getTrackedElementSignature() == this.newHeadDetails.getTrackedElementSignature()
  }

  copyNewHeadStylesheetElements() {
    for (const element of this.getNewHeadStylesheetElements()) {
      document.head.appendChild(element)
    }
  }

  copyNewHeadScriptElements() {
    for (const element of this.getNewHeadScriptElements()) {
      document.head.appendChild(this.createScriptElement(element))
    }
  }

  removeCurrentHeadProvisionalElements() {
    for (const element of this.getCurrentHeadProvisionalElements()) {
      document.head.removeChild(element)
    }
  }

  copyNewHeadProvisionalElements() {
    for (const element of this.getNewHeadProvisionalElements()) {
      document.head.appendChild(element)
    }
  }

  relocateCurrentBodyPermanentElements() {
    return this.getCurrentBodyPermanentElements().reduce((placeholders, permanentElement) => {
      const newElement = this.newSnapshot.getPermanentElementById(permanentElement.id)
      if (newElement) {
        const placeholder = createPlaceholderForPermanentElement(permanentElement)
        replaceElementWithElement(permanentElement, placeholder.element)
        replaceElementWithElement(newElement, permanentElement)
        return [...placeholders, placeholder]
      } else {
        return placeholders
      }
    }, [] as Placeholder[])
  }

  replacePlaceholderElementsWithClonedPermanentElements(placeholders: Placeholder[]) {
    for (const { element, permanentElement } of placeholders) {
      const clonedElement = permanentElement.cloneNode(true)
      replaceElementWithElement(element, clonedElement)
    }
  }

  activateNewBodyScriptElements() {
    for (const inertScriptElement of this.getNewBodyScriptElements()) {
      const activatedScriptElement = this.createScriptElement(inertScriptElement)
      replaceElementWithElement(inertScriptElement, activatedScriptElement)
    }
  }

  assignNewBody() {
    replaceElementWithElement(document.body, this.newBody)
  }

  focusFirstAutofocusableElement() {
    const element = this.newSnapshot.findFirstAutofocusableElement()
    if (elementIsFocusable(element)) {
      element.focus()
    }
  }

  getNewHeadStylesheetElements() {
    return this.newHeadDetails.getStylesheetElementsNotInDetails(this.currentHeadDetails)
  }

  getNewHeadScriptElements() {
    return this.newHeadDetails.getScriptElementsNotInDetails(this.currentHeadDetails)
  }

  getCurrentHeadProvisionalElements() {
    return this.currentHeadDetails.getProvisionalElements()
  }

  getNewHeadProvisionalElements() {
    return this.newHeadDetails.getProvisionalElements()
  }

  getCurrentBodyPermanentElements(): PermanentElement[] {
    return this.currentSnapshot.getPermanentElementsPresentInSnapshot(this.newSnapshot)
  }

  getNewBodyScriptElements() {
    return array(this.newBody.querySelectorAll("script"))
  }
}

function createPlaceholderForPermanentElement(permanentElement: PermanentElement) {
  const element = document.createElement("meta")
  element.setAttribute("name", "turbolinks-permanent-placeholder")
  element.setAttribute("content", permanentElement.id)
  return { element, permanentElement }
}

function replaceElementWithElement(fromElement: Element, toElement: Element) {
  const parentElement = fromElement.parentElement
  if (parentElement) {
    return parentElement.replaceChild(toElement, fromElement)
  }
}

function elementIsFocusable(element: any): element is { focus: () => void } {
  return element && typeof element.focus == "function"
}
