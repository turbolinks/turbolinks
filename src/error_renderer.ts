import { RenderCallback, RenderDelegate, Renderer } from "./renderer"
import { array } from "./util"

export class ErrorRenderer extends Renderer {
  readonly delegate: RenderDelegate
  readonly htmlElement: HTMLHtmlElement
  readonly newHead: HTMLHeadElement
  readonly newBody: HTMLBodyElement

  static render(delegate: RenderDelegate, callback: RenderCallback, html: string) {
    return new this(delegate, html).render(callback)
  }

  constructor(delegate: RenderDelegate, html: string) {
    super()
    this.delegate = delegate
    this.htmlElement = (() => {
      const htmlElement = document.createElement("html")
      htmlElement.innerHTML = html
      return htmlElement
    })()
    this.newHead = this.htmlElement.querySelector("head") || document.createElement("head")
    this.newBody = this.htmlElement.querySelector("body") || document.createElement("body")
  }

  render(callback: RenderCallback) {
    this.renderView(() => {
      this.replaceHeadAndBody()
      this.activateBodyScriptElements()
      callback()
    })
  }

  replaceHeadAndBody() {
    const { documentElement, head, body } = document
    documentElement.replaceChild(this.newHead, head)
    documentElement.replaceChild(this.newBody, body)
  }

  activateBodyScriptElements() {
    for (const replaceableElement of this.getScriptElements()) {
      const parentNode = replaceableElement.parentNode
      if (parentNode) {
        const element = this.createScriptElement(replaceableElement)
        parentNode.replaceChild(element, replaceableElement)
      }
    }
  }

  getScriptElements() {
    return array(document.documentElement.querySelectorAll("script"))
  }
}
