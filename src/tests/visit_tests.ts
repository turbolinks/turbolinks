import { TurbolinksTestCase } from "./helpers/turbolinks_test_case"
import { get } from "http"

export class VisitTests extends TurbolinksTestCase {
  async setup() {
    this.goToLocation("/fixtures/visit.html")
  }

  async "test programmatically visiting a same-origin location"() {
    const urlBeforeVisit = await this.location
    await this.visitLocation("/fixtures/one.html")

    const urlAfterVisit = await this.location
    this.assert.notEqual(urlBeforeVisit, urlAfterVisit)
    this.assert.equal(await this.visitAction, "advance")

    const { url: urlFromBeforeVisitEvent } = await this.nextEventNamed("turbolinks:before-visit")
    this.assert.equal(urlFromBeforeVisitEvent, urlAfterVisit)

    const { url: urlFromVisitEvent } = await this.nextEventNamed("turbolinks:visit")
    this.assert.equal(urlFromVisitEvent, urlAfterVisit)

    const { timing } = await this.nextEventNamed("turbolinks:load")
    this.assert.ok(timing)
  }

  async "test programmatically visiting a cross-origin location falls back to window.location"() {
    const urlBeforeVisit = await this.location
    await this.visitLocation("about:blank")

    const urlAfterVisit = await this.location
    this.assert.notEqual(urlBeforeVisit, urlAfterVisit)
    this.assert.equal(await this.visitAction, "load")
  }

  async "test visiting a location served with a non-HTML content type"() {
    const urlBeforeVisit = await this.location
    await this.visitLocation("/fixtures/svg")

    const url = await this.remote.getCurrentUrl()
    const contentType = await contentTypeOfURL(url)
    this.assert.equal(contentType, "image/svg+xml")

    const urlAfterVisit = await this.location
    this.assert.notEqual(urlBeforeVisit, urlAfterVisit)
    this.assert.equal(await this.visitAction, "load")
  }

  async "test canceling a before-visit event prevents navigation"() {
    this.cancelNextVisit()
    const urlBeforeVisit = await this.location

    this.clickSelector("#same-origin-link")
    await this.nextBeat
    this.assert(!await this.changedBody)

    const urlAfterVisit = await this.location
    this.assert.equal(urlAfterVisit, urlBeforeVisit)
  }

  async "test navigation by history is not cancelable"() {
    this.clickSelector("#same-origin-link")
    await this.drainEventLog()
    await this.nextBeat

    await this.goBack()
    this.assert(await this.changedBody)
  }

  async visitLocation(location: string) {
    this.remote.execute((location: string) => window.Turbolinks.visit(location), [location])
  }

  async cancelNextVisit() {
    this.remote.execute(() => addEventListener("turbolinks:before-visit", function eventListener(event) {
      removeEventListener("turbolinks:before-visit", eventListener, false)
      event.preventDefault()
    }, false))
  }
}

function contentTypeOfURL(url: string): Promise<string | undefined> {
  return new Promise(resolve => {
    get(url, ({ headers }) => resolve(headers["content-type"]))
  })
}

VisitTests.registerSuite()
