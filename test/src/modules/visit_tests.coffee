QUnit.module "Visit"

visitTest = (name, callback) ->
  sessionTest name, (assert, session, done) ->
    session.goToLocation("/fixtures/visit.html").then (navigation) ->
      callback(assert, session, done)

visitTest "programmatically visiting a same-origin location", (assert, session, done) ->
  session.evaluate("Turbolinks.visit('/fixtures/one.html')")
  session.waitForEvent "turbolinks:visit", (event) ->
    session.waitForNavigation().then (navigation) ->
      assert.equal(event.data.url, navigation.location.toString())
      assert.equal(navigation.location.pathname, "/fixtures/one.html")
      assert.equal(navigation.action, "push")
      done()

visitTest "programmatically visiting a cross-origin location falls back to window.location", (assert, session, done) ->
  session.evaluate("Turbolinks.visit('about:blank')")
  session.waitForEvent "turbolinks:visit", (event) ->
    session.waitForNavigation().then (navigation) ->
      assert.equal(event.data.url, "about:blank")
      assert.equal(navigation.location, "about:blank")
      assert.equal(navigation.action, "load")
      done()

visitTest "canceling a visit event prevents navigation", (assert, session, done) ->
  session.clickSelector("#same-origin-link")
  session.waitForEvent "turbolinks:visit", (event) ->
    event.preventDefault()
    session.wait().then ->
      assert.equal(session.element.location.pathname, "/fixtures/visit.html")
      done()
