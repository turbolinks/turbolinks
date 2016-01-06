replicantSessionTest = (name, callback) ->
  QUnit.test name, (assert) ->
    done = assert.async()
    withReplicantSession (session, teardown) ->
      callback assert, session, ->
        teardown()
        done()

withReplicantSession = (callback) ->
  fixture = document.querySelector("#qunit-fixture")
  element = document.createElement("replicant-frame")
  session = element.createSession()

  element.addEventListener "replicant-initialize", ->
    callback session, ->
      fixture.removeChild(element)

  fixture.appendChild(element)

replicantSessionTest "following a link", (assert, session, done) ->
  session.goToLocation("/fixtures/index.html").then (navigation) ->
    assert.equal(navigation.location.pathname, "/fixtures/index.html")
    assert.equal(navigation.action, "load")
    session.clickSelector("a[href]").then (navigation) ->
      session.waitForEvent("turbolinks:load").then ->
        assert.equal(navigation.location.pathname, "/fixtures/one.html")
        assert.equal(navigation.action, "push")
        done()
