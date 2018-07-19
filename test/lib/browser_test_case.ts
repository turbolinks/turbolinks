import { InternTestCase } from "./intern_test_case"

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

  async clickSelector(selector: string): Promise<void> {
    return this.remote.findByCssSelector(selector).click()
  }

  get scrollPosition(): Promise<{ x: number, y: number }> {
    return this.evaluate(() => ({ x: window.scrollX, y: window.scrollY }))
  }

  async isScrolledTo(selector: string): Promise<boolean> {
    const { y: pageY } = await this.scrollPosition
    const { y: elementY } = await this.remote.findByCssSelector(selector).getPosition()
    const offset = pageY - elementY
    return offset > -1 && offset < 1
  }

  async evaluate<T>(callback: () => T): Promise<T> {
    return await this.remote.execute(callback)
  }
}
