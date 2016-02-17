QUnit.module "Visit"

visitTest = (name, callback) ->
  sessionTest name, (assert, session, done) ->
    session.goToLocation "/fixtures/visit.html", (navigation) ->
      callback(assert, session, done)

visitTest "programmatically visiting a same-origin location", (assert, session, done) ->
  session.evaluate("Turbolinks.visit('/fixtures/one.html')")
  eventLocations = {}
  session.waitForEvent "turbolinks:before-visit", (event) ->
    eventLocations.beforeVisit = event.data.url
  session.waitForEvent "turbolinks:visit", (event) ->
    eventLocations.visit = event.data.url
  session.waitForNavigation (navigation) ->
    assert.equal(eventLocations.beforeVisit, navigation.location)
    assert.equal(eventLocations.visit, navigation.location)
    assert.equal(navigation.location.pathname, "/fixtures/one.html")
    assert.equal(navigation.action, "push")
    done()

visitTest "programmatically visiting a cross-origin location falls back to window.location", (assert, session, done) ->
  session.evaluate("Turbolinks.visit('about:blank')")
  session.waitForEvent "turbolinks:before-visit", (event) ->
    session.waitForNavigation (navigation) ->
      assert.equal(event.data.url, "about:blank")
      assert.equal(navigation.location, "about:blank")
      assert.equal(navigation.action, "load")
      done()

visitTest "canceling a visit event prevents navigation", (assert, session, done) ->
  session.clickSelector("#same-origin-link")
  session.waitForEvent "turbolinks:before-visit", (event) ->
    event.preventDefault()
    session.wait ->
      assert.equal(session.element.location.pathname, "/fixtures/visit.html")
      done()

visitTest "navigation by history is not cancelable", (assert, session, done) ->
  session.clickSelector "#same-origin-link", ->
    eventLocations = {}
    session.waitForEvent "turbolinks:before-visit", (event) ->
      eventLocations.beforeVisit = event.data.url
    session.waitForEvent "turbolinks:visit", (event) ->
      eventLocations.visit = event.data.url
    session.goBack (navigation) ->
      assert.notOk(eventLocations.beforeVisit)
      assert.equal(eventLocations.visit, navigation.location)
      done()
