import { TurbolinksTestCase } from "./helpers/turbolinks_test_case"

export class AsyncScriptTests extends TurbolinksTestCase {
  async setup() {
    await this.goToLocation("/fixtures/async_script.html")
  }

  async "test does not emit turbolinks:load when loaded asynchronously after DOMContentLoaded"() {
    const events = await this.eventLogChannel.read()
    this.assert.deepEqual(events, [])
  }

  async "test following a link when loaded asynchronously after DOMContentLoaded"() {
    this.clickSelector("#async-link")
    await this.nextBody
    this.assert.equal(await this.visitAction, "advance")
  }
}

AsyncScriptTests.registerSuite()
