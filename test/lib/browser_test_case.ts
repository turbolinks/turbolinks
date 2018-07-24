import { InternTestCase } from "./intern_test_case"
import { Element } from "@theintern/leadfoot"

export class BrowserTestCase extends InternTestCase {
  async goToLocation(location: string): Promise<void> {
    const processedLocation = location.match(/^\//) ? location.slice(1) : location
    return this.remote.get(processedLocation)
  }

  async goBack(): Promise<void> {
    return this.remote.goBack()
  }

  async goForward(): Promise<void> {
    return this.remote.goForward()
  }

  async hasSelector(selector: string) {
    return (await this.remote.findAllByCssSelector(selector)).length > 0
  }

  async querySelector(selector: string) {
    return this.remote.findByCssSelector(selector)
  }

  async clickSelector(selector: string): Promise<void> {
    return this.remote.findByCssSelector(selector).click()
  }

  get scrollPosition(): Promise<{ x: number, y: number }> {
    return this.evaluate(() => ({ x: window.scrollX, y: window.scrollY }))
  }

  async isScrolledToSelector(selector: string): Promise<boolean> {
    const { y: pageY } = await this.scrollPosition
    const { y: elementY } = await this.remote.findByCssSelector(selector).getPosition()
    const offset = pageY - elementY
    return offset > -1 && offset < 1
  }

  async evaluate<T>(callback: () => T): Promise<T> {
    return await this.remote.execute(callback)
  }

  get head(): Promise<Element> {
    return this.evaluate(() => document.head as any)
  }

  get body(): Promise<Element> {
    return this.evaluate(() => document.body as any)
  }

  get location(): Promise<string> {
    return this.evaluate(() => location.toString())
  }

  get pathname(): Promise<string> {
    return this.evaluate(() => location.pathname)
  }

  get hash(): Promise<string> {
    return this.evaluate(() => location.hash)
  }
}
