#= require browser

withBrowserSession = (callback) ->
  fixture = document.querySelector("#qunit-fixture")

  {element} = agent = Browser.Agent.create()
  session = new Browser.Session agent
  fixture.appendChild(element)

  requestAnimationFrame ->
    callback session, ->
      fixture.removeChild(element)

browserSessionTest = (name, callback) ->
  QUnit.test name, (assert) ->
    done = assert.async()
    withBrowserSession (session, teardown) ->
      callback session, ->
        teardown()
        done()

do ->
  {equal} = QUnit

  browserSessionTest "following a link", (session, done) ->
    session.navigateTo "/fixtures/index.html", (location, action) ->
      equal location, "http://localhost:9876/fixtures/index.html"
      equal action, "load"
      session.clickSelector "a[href]", (location, action) ->
        equal location, "http://localhost:9876/fixtures/one.html"
        equal action, "push"
        done()
