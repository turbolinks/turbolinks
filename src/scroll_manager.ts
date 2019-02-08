import { Position } from "./types"

export interface ScrollManagerDelegate {
  scrollPositionChanged(position: Position): void
}

export class ScrollManager {
  readonly delegate: ScrollManagerDelegate
  started = false

  constructor(delegate: ScrollManagerDelegate) {
    this.delegate = delegate
  }

  start() {
    if (!this.started) {
      addEventListener("scroll", this.onScroll, false)
      this.onScroll()
      this.started = true
    }
  }

  stop() {
    if (this.started) {
      removeEventListener("scroll", this.onScroll, false)
      this.started = false
    }
  }

  scrollToElement(element: Element) {
    element.scrollIntoView()
  }

  scrollToPosition({ x, y }: Position) {
    window.scrollTo(x, y)
  }

  onScroll = () => {
    this.updatePosition({ x: window.pageXOffset, y: window.pageYOffset })
  }

  // Private

  updatePosition(position: Position) {
    this.delegate.scrollPositionChanged(position)
  }
}
