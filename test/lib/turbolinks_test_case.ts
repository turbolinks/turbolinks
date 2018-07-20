import { BrowserTestCase } from "./browser_test_case"
import { RemoteChannel } from "./remote_channel"

declare global {
  interface Window {
    Turbolinks: any
    pageIdentifier: string | undefined
  }
}

type EventLog = [string, any]

export class TurbolinksTestCase extends BrowserTestCase {
  private lastPageIdentifier?: string
  private eventLogChannel: RemoteChannel<EventLog> = new RemoteChannel(this.remote, "eventLogs")

  async beforeTest() {
    this.lastPageIdentifier = await this.pageIdentifier
    await this.eventLogChannel.drain()
  }

  get nextWindowHandle(): Promise<string> {
    return (async (nextHandle?: string) => {
      do {
        const handle = await this.remote.getCurrentWindowHandle()
        const handles = await this.remote.getAllWindowHandles()
        nextHandle = handles[handles.indexOf(handle) + 1]
      } while (!nextHandle)
      return nextHandle
    })()
  }

  get nextPageChange(): Promise<void> {
    return (async () => {
      let pageIdentifier: string
      do pageIdentifier = await this.pageIdentifier
      while (pageIdentifier == this.lastPageIdentifier)
    })()
  }

  async pageNotChangedWithin(duration: number): Promise<boolean> {
    const pageIdentifier = await this.pageIdentifier
    await this.remote.sleep(duration)
    return pageIdentifier == await this.pageIdentifier
  }

  async nextEventNamed(eventName: string): Promise<any> {
    let record: EventLog | undefined
    while (!record) {
      const records = await this.eventLogChannel.read(1)
      record = records.find(([name]) => name == eventName)
    }
    return record[1]
  }

  get visitAction(): Promise<string> {
    return this.evaluate(() => {
      try {
        return window.Turbolinks.controller.currentVisit.action
      } catch (error) {
        return "load"
      }
    })
  }

  private get pageIdentifier(): Promise<string> {
    return this.evaluate(() => {
      return window.pageIdentifier = (window.pageIdentifier || Math.random().toFixed(20))
    })
  }
}
