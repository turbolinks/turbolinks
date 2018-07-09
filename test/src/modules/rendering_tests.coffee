QUnit.module "Rendering", beforeEach: -> window.focus()

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

renderingTest "reloads when turbolinks-visit-control setting is reload", (assert, session, done) ->
  responseReceived = false
  session.waitForEvent "turbolinks:request-end", (event) ->
    responseReceived = true

  rendered = false
  session.waitForEvent "turbolinks:render", (event) ->
    rendered = true

  session.clickSelector "#visit-control-reload-link", (navigation) ->
    # Turbolinks calls pushState first, after issuing the request
    # but before receiving the response. Wait again for the reload.
    assert.equal(navigation.location.pathname, "/fixtures/visit_control_reload.html")
    assert.equal(navigation.action, "push")
    session.waitForNavigation (navigation) ->
      assert.ok(responseReceived)
      assert.notOk(rendered)
      assert.equal(navigation.location.pathname, "/fixtures/visit_control_reload.html")
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

renderingTest "preserves permanent elements", (assert, session, done) ->
  permanentElement = do findPermanentElement = ->
    session.element.document.getElementById("permanent")

  assert.equal(permanentElement.textContent, "Rendering")
  session.clickSelector "#permanent-element-link", ->
    session.waitForEvent "turbolinks:render", ->
      assert.equal(findPermanentElement(), permanentElement)
      assert.equal(permanentElement.textContent, "Rendering")
      session.goBack()
      session.waitForEvent "turbolinks:render", ->
        assert.equal(findPermanentElement(), permanentElement)
        done()

renderingTest "entire body is swapped on typical render", (assert, session, done) ->
  oldBody = session.element.document.body
  session.clickSelector "#same-origin-link", ->
    session.waitForEvent "turbolinks:render", ->
      newBody = session.element.document.body
      assert.notEqual newBody, oldBody
      done()

renderingTest "entire body is swapped when only new page has root element", (assert, session, done) ->
  oldBody = session.element.document.body
  session.clickSelector "#root-element-link", ->
    session.waitForEvent "turbolinks:render", ->
      newBody = session.element.document.body
      assert.notEqual newBody, oldBody
      done()

renderingTest "entire body is swapped when only old page has root element", (assert, session, done) ->
  session.clickSelector "#root-element-link", ->
    session.waitForEvent "turbolinks:load", ->
      rootElementOneBody = session.element.document.body
      assert.equal rootElementOneBody.querySelector("h1").textContent, "Root element one"
      session.clickSelector "#home-link", ->
        session.waitForEvent "turbolinks:load", ->
          homeBody = session.element.document.body
          assert.notEqual rootElementOneBody, homeBody
          done()

renderingTest "only root element is swapped between root element pages", (assert, session, done) ->
  session.clickSelector "#root-element-link", ->
    session.waitForEvent "turbolinks:load", ->
      rootElementOneBody = session.element.document.body
      assert.equal rootElementOneBody.querySelector("h1").textContent, "Root element one"
      session.clickSelector "#root-element-link", ->
        session.waitForEvent "turbolinks:load", ->
          rootElementTwoBody = session.element.document.body
          assert.equal rootElementOneBody, rootElementTwoBody
          assert.equal rootElementTwoBody.querySelector("h1").textContent, "Root element two"
          assert.equal rootElementTwoBody.querySelector("footer").textContent, "Footer from page one"
          done()

renderingTest "before-cache event", (assert, session, done) ->
  {body} = session.element.document
  session.clickSelector "#same-origin-link", ->
    session.waitForEvent "turbolinks:before-cache", ->
      body.querySelector("h1").textContent = "Modified"
    session.waitForEvent "turbolinks:render", ->
      session.goBack()
      session.waitForEvent "turbolinks:render", ->
        assert.equal(body.querySelector("h1").textContent, "Modified")
        done()

renderingTest "mutation record as before-cache notification", (assert, session, done) ->
  {documentElement, body} = session.element.document
  session.clickSelector("#same-origin-link")
  observe documentElement, childList: true, (stop, {removedNodes}) ->
    if body in removedNodes
      stop()
      body.querySelector("h1").textContent = "Modified"
      session.goBack()
      session.waitForEvent "turbolinks:render", ->
        assert.equal(body.querySelector("h1").textContent, "Modified")
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

observe = (element, options, callback) ->
  observer = new MutationObserver (records) ->
    stop = -> observer.disconnect()
    for record in records
      callback(stop, record)
  observer.observe(element, options)
