QUnit.module "Event"

eventTest = (name, callback) ->
  sessionTest name, (assert, session, done) ->
    session.goToLocation "/fixtures/event.html", (navigation) ->
      assert.equal(navigation.location.pathname, "/fixtures/event.html")
      callback(assert, session, done)

eventTest "fires turbolinks:load, even for unsupported browsers", (assert, session, done) ->
  assert.equal(session.element.window.turbolinksLoadFired, true)
  done()
