import { BrowserTestCase } from "./browser_test_case"
import { RemoteChannel } from "./remote_channel"
import { Element } from "@theintern/leadfoot"

type EventLog = [string, any]

export class TurbolinksTestCase extends BrowserTestCase {
  eventLogChannel: RemoteChannel<EventLog> = new RemoteChannel(this.remote, "eventLogs")
  lastBody?: Element

  async beforeTest() {
    await this.drainEventLog()
    this.lastBody = await this.body
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

  async nextEventNamed(eventName: string): Promise<any> {
    let record: EventLog | undefined
    while (!record) {
      const records = await this.eventLogChannel.read(1)
      record = records.find(([name]) => name == eventName)
    }
    return record[1]
  }

  get nextBeat(): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, 100))
  }

  get nextBody(): Promise<Element> {
    return (async () => {
      let body
      do body = await this.changedBody
      while (!body)
      return this.lastBody = body
    })()
  }

  get changedBody(): Promise<Element | undefined> {
    return (async () => {
      const body = await this.body
      if (!this.lastBody || this.lastBody.elementId != body.elementId) {
        return body
      }
    })()
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

  drainEventLog() {
    return this.eventLogChannel.drain()
  }
}

declare global {
  interface Window {
    Turbolinks: any
  }
}
