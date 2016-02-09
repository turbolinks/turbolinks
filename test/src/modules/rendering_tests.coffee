QUnit.module "Rendering"

renderingTest = (name, callback) ->
  sessionTest name, (assert, session, done) ->
    session.goToLocation "/fixtures/rendering.html", (navigation) ->
      callback(assert, session, done)

renderingTest "before-render and render events", (assert, session, done) ->
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
