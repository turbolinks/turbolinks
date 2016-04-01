QUnit.module "Rendering"

renderingTest = (name, callback) ->
  sessionTest name, (assert, session, done) ->
    session.goToLocation "/fixtures/rendering.html", (navigation) ->
      callback(assert, session, done)

renderingTest "triggers before-render and render events", (assert, session, done) ->
  session.clickSelector("#same-origin-link")
  session.waitForEvent "turbolinks:before-render", (event) ->
    {newBody} = event.data
    assert.notEqual(session.element.document.body, newBody)

    h1 = newBody.querySelector("h1")
    assert.equal(h1.textContent, "One")

    session.waitForEvent "turbolinks:render", (event) ->
      assert.equal(session.element.document.body, newBody)

      session.waitForEvent "turbolinks:load", ->
        done()

renderingTest "reloads when tracked elements change", (assert, session, done) ->
  responseReceived = false
  session.waitForEvent "turbolinks:request-end", (event) ->
    responseReceived = true

  rendered = false
  session.waitForEvent "turbolinks:render", (event) ->
    rendered = true

  session.clickSelector "#tracked-asset-change-link", (navigation) ->
    # Turbolinks calls pushState first, after issuing the request
    # but before receiving the response. Wait again for the reload.
    assert.equal(navigation.location.pathname, "/fixtures/tracked_asset_change.html")
    assert.equal(navigation.action, "push")
    session.waitForNavigation (navigation) ->
      assert.ok(responseReceived)
      assert.notOk(rendered)
      assert.equal(navigation.location.pathname, "/fixtures/tracked_asset_change.html")
      assert.equal(navigation.action, "load")
      done()

renderingTest "accumulates asset elements in head", (assert, session, done) ->
  originalElements = getAssetElements(session.element.document)
  session.clickSelector "#additional-assets-link", ->
    session.waitForEvent "turbolinks:render", ->
      newElements = getAssetElements(session.element.document)
      assert.notDeepEqual(originalElements, newElements)
      session.goBack()
      session.waitForEvent "turbolinks:render", ->
        finalElements = getAssetElements(session.element.document)
        assert.deepEqual(newElements, finalElements)
        done()

renderingTest "replaces provisional elements in head", (assert, session, done) ->
  assert.notOk(session.element.document.querySelector("meta[name=test]"))
  originalElements = getProvisionalElements(session.element.document)
  session.clickSelector "#same-origin-link", ->
    session.waitForEvent "turbolinks:render", ->
      newElements = getProvisionalElements(session.element.document)
      assert.ok(session.element.document.querySelector("meta[name=test]"))
      assert.notDeepEqual(originalElements, newElements)
      session.goBack()
      session.waitForEvent "turbolinks:render", ->
        finalElements = getProvisionalElements(session.element.document)
        assert.notOk(session.element.document.querySelector("meta[name=test]"))
        assert.notDeepEqual(originalElements, finalElements)
        assert.notDeepEqual(newElements, finalElements)
        done()

renderingTest "evaluates head script elements once", (assert, session, done) ->
  assert.equal(session.element.window.headScriptEvaluationCount, null)
  session.clickSelector "#head-script-link", ->
    session.waitForEvent "turbolinks:render", ->
      assert.equal(session.element.window.headScriptEvaluationCount, 1)
      session.goBack()
      session.waitForEvent "turbolinks:render", ->
        assert.equal(session.element.window.headScriptEvaluationCount, 1)
        session.clickSelector "#head-script-link", ->
          session.waitForEvent "turbolinks:render", ->
            assert.equal(session.element.window.headScriptEvaluationCount, 1)
            done()

renderingTest "evaluates body script elements on each render", (assert, session, done) ->
  assert.equal(session.element.window.bodyScriptEvaluationCount, null)
  session.clickSelector "#body-script-link", ->
    session.waitForEvent "turbolinks:render", ->
      assert.equal(session.element.window.bodyScriptEvaluationCount, 1)
      session.goBack()
      session.waitForEvent "turbolinks:render", ->
        assert.equal(session.element.window.bodyScriptEvaluationCount, 1)
        session.clickSelector "#body-script-link", ->
          session.waitForEvent "turbolinks:render", ->
            assert.equal(session.element.window.bodyScriptEvaluationCount, 2)
            done()

renderingTest "does not evaluate data-turbolinks-eval=false scripts", (assert, session, done) ->
  assert.equal(session.element.window.bodyScriptEvaluationCount, null)
  session.clickSelector "#eval-false-script-link", ->
    session.waitForEvent "turbolinks:render", ->
      assert.equal(session.element.window.bodyScriptEvaluationCount, null)
      done()

renderingTest "error pages", (assert, session, done) ->
  session.clickSelector "#nonexistent-link", ->
    session.waitForEvent "turbolinks:render", ->
      assert.equal(session.element.document.body.textContent, "Not found")
      done()

getAssetElements = (document = document) ->
  selectChildren document.head, (el) -> match(el, "script, style, link[rel=stylesheet]")

getProvisionalElements = (document = document) ->
  selectChildren document.head, (el) -> not match(el, "script, style, link[rel=stylesheet]")

selectChildren = (element, test) ->
  node for node in element.childNodes when node.nodeType is Node.ELEMENT_NODE and test(node)

match = (element, selector) ->
  html = document.documentElement
  fn = html.matchesSelector ? html.webkitMatchesSelector ? html.msMatchesSelector ? html.mozMatchesSelector
  fn.call(element, selector)
