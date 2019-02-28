import { array } from "./util"

type ElementDetailMap = { [outerHTML: string]: ElementDetails }

type ElementDetails = { type?: ElementType, tracked: boolean, elements: Element[] }

type ElementType = "script" | "stylesheet"

export class HeadDetails {
  readonly detailsByOuterHTML: ElementDetailMap

  static fromHeadElement(headElement: HTMLHeadElement | null): HeadDetails {
    const children = headElement ? array(headElement.children) : []
    return new this(children)
  }

  constructor(children: Element[]) {
    this.detailsByOuterHTML = children.reduce((result, element) => {
      const { outerHTML } = element
      const details: ElementDetails
        = outerHTML in result
        ? result[outerHTML]
        : {
          type: elementType(element),
          tracked: elementIsTracked(element),
          elements: []
        }
      return {
        ...result,
        [outerHTML]: {
          ...details,
          elements: [...details.elements, element]
        }
      }
    }, {} as ElementDetailMap)
  }

  getTrackedElementSignature(): string {
    return Object.keys(this.detailsByOuterHTML)
      .filter(outerHTML => this.detailsByOuterHTML[outerHTML].tracked)
      .join("")
  }

  getScriptElementsNotInDetails(headDetails: HeadDetails) {
    return this.getElementsMatchingTypeNotInDetails("script", headDetails)
  }

  getStylesheetElementsNotInDetails(headDetails: HeadDetails) {
    return this.getElementsMatchingTypeNotInDetails("stylesheet", headDetails)
  }

  getElementsMatchingTypeNotInDetails(matchedType: ElementType, headDetails: HeadDetails) {
    return Object.keys(this.detailsByOuterHTML)
      .filter(outerHTML => !(outerHTML in headDetails.detailsByOuterHTML))
      .map(outerHTML => this.detailsByOuterHTML[outerHTML])
      .filter(({ type }) => type == matchedType)
      .map(({ elements: [element] }) => element)
  }

  getProvisionalElements(): Element[] {
    return Object.keys(this.detailsByOuterHTML).reduce((result, outerHTML) => {
      const { type, tracked, elements } = this.detailsByOuterHTML[outerHTML]
      if (type == null && !tracked) {
        return [...result, ...elements]
      } else if (elements.length > 1) {
        return [...result, ...elements.slice(1)]
      } else {
        return result
      }
    }, [] as Element[])
  }

  getMetaValue(name: string): string | null {
    const element = this.findMetaElementByName(name)
    return element
      ? element.getAttribute("content")
      : null
  }

  findMetaElementByName(name: string) {
    return Object.keys(this.detailsByOuterHTML).reduce((result, outerHTML) => {
      const { elements: [element] } = this.detailsByOuterHTML[outerHTML]
      return elementIsMetaElementWithName(element, name) ? element : result
    }, undefined as Element | undefined)
  }
}

function elementType(element: Element) {
  if (elementIsScript(element)) {
    return "script"
  } else if (elementIsStylesheet(element)) {
    return "stylesheet"
  }
}

function elementIsTracked(element: Element) {
  return element.getAttribute("data-turbolinks-track") == "reload"
}

function elementIsScript(element: Element) {
  const tagName = element.tagName.toLowerCase()
  return tagName == "script"
}

function elementIsStylesheet(element: Element) {
  const tagName = element.tagName.toLowerCase()
  return tagName == "style" || (tagName == "link" && element.getAttribute("rel") == "stylesheet")
}

function elementIsMetaElementWithName(element: Element, name: string) {
  const tagName = element.tagName.toLowerCase()
  return tagName == "meta" && element.getAttribute("name") == name
}
