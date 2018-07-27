import { TurbolinksTestCase } from "../lib/turbolinks_test_case"
import { Element } from "@theintern/leadfoot"

export class RenderingTests extends TurbolinksTestCase {
  async setup() {
    await this.goToLocation("/fixtures/rendering.html")
  }

  async "test triggers before-render and render events"() {
    this.clickSelector("#same-origin-link")
    const { newBody } = await this.nextEventNamed("turbolinks:before-render")

    const h1 = await this.querySelector("h1")
    this.assert.equal(await h1.getVisibleText(), "One")

    await this.nextEventNamed("turbolinks:render")
    this.assert(await newBody.equals(await this.body))
  }

  async "test triggers before-render and render events for error pages"() {
    this.clickSelector("#nonexistent-link")
    const { newBody } = await this.nextEventNamed("turbolinks:before-render")

    this.assert.equal(await newBody.getVisibleText(), "404 Not Found: /nonexistent")

    await this.nextEventNamed("turbolinks:render")
    this.assert(await newBody.equals(await this.body))
  }

  async "test reloads when tracked elements change"() {
    this.clickSelector("#tracked-asset-change-link")
    await this.nextBody
    this.assert.equal(await this.pathname, "/fixtures/tracked_asset_change.html")
    this.assert.equal(await this.visitAction, "load")
  }

  async "test reloads when turbolinks-visit-control setting is reload"() {
    this.clickSelector("#visit-control-reload-link")
    await this.nextBody
    this.assert.equal(await this.pathname, "/fixtures/visit_control_reload.html")
    this.assert.equal(await this.visitAction, "load")
  }

  async "test accumulates asset elements in head"() {
    const originalElements = await this.assetElements

    this.clickSelector("#additional-assets-link")
    await this.nextBody
    const newElements = await this.assetElements
    this.assert.notDeepEqual(newElements, originalElements)

    this.goBack()
    await this.nextBody
    const finalElements = await this.assetElements
    this.assert.deepEqual(finalElements, newElements)
  }

  async "test replaces provisional elements in head"() {
    const originalElements = await this.provisionalElements
    this.assert(!await this.hasSelector("meta[name=test]"))

    this.clickSelector("#same-origin-link")
    await this.nextBody
    const newElements = await this.provisionalElements
    this.assert.notDeepEqual(newElements, originalElements)
    this.assert(await this.hasSelector("meta[name=test]"))

    this.goBack()
    await this.nextBody
    const finalElements = await this.provisionalElements
    this.assert.notDeepEqual(finalElements, newElements)
    this.assert(!await this.hasSelector("meta[name=test]"))
  }

  async "test evaluates head script elements once"() {
    this.assert.equal(await this.headScriptEvaluationCount, undefined)

    this.clickSelector("#head-script-link")
    await this.nextEventNamed("turbolinks:render")
    this.assert.equal(await this.headScriptEvaluationCount, 1)

    this.goBack()
    await this.nextEventNamed("turbolinks:render")
    this.assert.equal(await this.headScriptEvaluationCount, 1)

    this.clickSelector("#head-script-link")
    await this.nextEventNamed("turbolinks:render")
    this.assert.equal(await this.headScriptEvaluationCount, 1)
  }

  async "test evaluates body script elements on each render"() {
    this.assert.equal(await this.bodyScriptEvaluationCount, undefined)

    this.clickSelector("#body-script-link")
    await this.nextEventNamed("turbolinks:render")
    this.assert.equal(await this.bodyScriptEvaluationCount, 1)

    this.goBack()
    await this.nextEventNamed("turbolinks:render")
    this.assert.equal(await this.bodyScriptEvaluationCount, 1)

    this.clickSelector("#body-script-link")
    await this.nextEventNamed("turbolinks:render")
    this.assert.equal(await this.bodyScriptEvaluationCount, 2)
  }

  async "test does not evaluate data-turbolinks-eval=false scripts"() {
    this.clickSelector("#eval-false-script-link")
    await this.nextEventNamed("turbolinks:render")
    this.assert.equal(await this.bodyScriptEvaluationCount, undefined)
  }

  async "test preserves permanent elements"() {
    let permanentElement = await this.permanentElement
    this.assert.equal(await permanentElement.getVisibleText(), "Rendering")

    this.clickSelector("#permanent-element-link")
    await this.nextEventNamed("turbolinks:render")
    this.assert(await permanentElement.equals(await this.permanentElement))
    this.assert.equal(await permanentElement.getVisibleText(), "Rendering")

    this.goBack()
    await this.nextEventNamed("turbolinks:render")
    this.assert(await permanentElement.equals(await this.permanentElement))
  }

  async "test before-cache event"() {
    this.beforeCache(body => body.innerHTML = "Modified")
    this.clickSelector("#same-origin-link")
    await this.nextBody
    await this.goBack()
    const body = await this.nextBody
    this.assert(await body.getVisibleText(), "Modified")
  }

  async "test mutation record as before-cache notification"() {
    this.modifyBodyAfterRemoval()
    this.clickSelector("#same-origin-link")
    await this.nextBody
    await this.goBack()
    const body = await this.nextBody
    this.assert(await body.getVisibleText(), "Modified")
  }

  async "test error pages"() {
    this.clickSelector("#nonexistent-link")
    const body = await this.nextBody
    this.assert.equal(await body.getVisibleText(), "404 Not Found: /nonexistent")
    await this.goBack()
  }

  get assetElements(): Promise<Element[]> {
    return filter(this.headElements, isAssetElement)
  }

  get provisionalElements(): Promise<Element[]> {
    return filter(this.headElements, async element => !await isAssetElement(element))
  }

  get headElements(): Promise<Element[]> {
    return this.evaluate(() => [...document.head.children] as any[])
  }

  get permanentElement(): Promise<Element> {
    return this.querySelector("#permanent")
  }

  get headScriptEvaluationCount(): Promise<number | undefined> {
    return this.evaluate(() => window.headScriptEvaluationCount)
  }

  get bodyScriptEvaluationCount(): Promise<number | undefined> {
    return this.evaluate(() => window.bodyScriptEvaluationCount)
  }

  async modifyBodyBeforeCaching() {
    return this.remote.execute(() => addEventListener("turbolinks:before-cache", function eventListener(event) {
      removeEventListener("turbolinks:before-cache", eventListener, false)
      document.body.innerHTML = "Modified"
    }, false))
  }

  async beforeCache(callback: (body: HTMLElement) => void) {
    return this.remote.execute((callback: (body: HTMLElement) => void) => {
      addEventListener("turbolinks:before-cache", function eventListener(event) {
        removeEventListener("turbolinks:before-cache", eventListener, false)
        callback(document.body)
      }, false)
    }, [callback])
  }

  async modifyBodyAfterRemoval() {
    return this.remote.execute(() => {
      const { documentElement, body } = document
      const observer = new MutationObserver(records => {
        for (const record of records) {
          if ([...record.removedNodes].indexOf(body) > -1) {
            body.innerHTML = "Modified"
            observer.disconnect()
            break
          }
        }
      })
      observer.observe(documentElement, { childList: true })
    })
  }
}

async function filter<T>(promisedValues: Promise<T[]>, predicate: (value: T) => Promise<boolean>): Promise<T[]> {
  const values = await promisedValues
  const matches = await Promise.all(values.map(value => predicate(value)))
  return matches.reduce((result, match, index) => result.concat(match ? values[index] : []), [] as T[])
}

async function isAssetElement(element: Element): Promise<boolean> {
  const tagName = await element.getTagName()
  const relValue = await element.getAttribute("rel")
  return tagName == "script" || tagName == "style" || (tagName == "link" && relValue == "stylesheet")
}

declare global {
  interface Window {
    headScriptEvaluationCount?: number
    bodyScriptEvaluationCount?: number
  }
}

RenderingTests.registerSuite()
