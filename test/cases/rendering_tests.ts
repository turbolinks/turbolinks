import { TurbolinksTestCase } from "../lib/turbolinks_test_case"

export class RenderingTests extends TurbolinksTestCase {
  async setup() {
    await this.goToLocation("/test/fixtures/rendering.html")
  }

  async "test triggers before-render and render events"() {
    this.clickSelector("#same-origin-link")
    const { newBody } = await this.nextEventNamed("turbolinks:before-render")

    const h1 = await this.querySelector("h1")
    this.assert.equal(await h1.getVisibleText(), "One")

    await this.nextEventNamed("turbolinks:render")
    this.assert(await newBody.equals(await this.body))
  }

  async "test reloads when tracked elements change"() {

  }

  async "test reloads when turbolinks-visit-control setting is reload"() {

  }

  async "test accumulates asset elements in head"() {

  }

  async "test replaces provisional elements in head"() {

  }

  async "test evaluates head script elements once"() {

  }

  async "test evaluates body script elements on each render"() {

  }

  async "test does not evaluate data-turbolinks-eval=false scripts"() {

  }

  async "test preserves permanent elements"() {

  }

  async "test before-cache event"() {

  }

  async "test mutation record as before-cache notification"() {

  }

  async "test error pages"() {

  }

  get body() {
    return this.evaluate(() => document.body)
  }
}

RenderingTests.registerSuite()
