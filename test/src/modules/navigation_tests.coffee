QUnit.module "Navigation"

navigationTest = (name, callback) ->
  sessionTest name, (assert, session, done) ->
    session.goToLocation "/fixtures/navigation.html", (navigation) ->
      assert.equal(navigation.location.pathname, "/fixtures/navigation.html")
      assert.equal(navigation.action, "load")
      callback(assert, session, done)

navigationTest "following a same-origin unannotated link", (assert, session, done) ->
  session.clickSelector "#same-origin-unannotated-link", (navigation) ->
    session.waitForEvent "turbolinks:load", ->
      assert.equal(navigation.location.pathname, "/fixtures/one.html")
      assert.equal(navigation.action, "push")
      done()

navigationTest "following a same-origin data-turbolinks-action=replace link", (assert, session, done) ->
  session.clickSelector "#same-origin-replace-link", (navigation) ->
    session.waitForEvent "turbolinks:load", ->
      assert.equal(navigation.location.pathname, "/fixtures/one.html")
      assert.equal(navigation.action, "replace")
      done()

navigationTest "following a same-origin data-turbolinks=false link", (assert, session, done) ->
  session.clickSelector "#same-origin-false-link", (navigation) ->
    assert.equal(navigation.location.pathname, "/fixtures/one.html")
    assert.equal(navigation.action, "load")
    done()

navigationTest "following a same-origin unannotated link inside a data-turbolinks=false container", (assert, session, done) ->
  session.clickSelector "#same-origin-unannotated-link-inside-false-container", (navigation) ->
    assert.equal(navigation.location.pathname, "/fixtures/one.html")
    assert.equal(navigation.action, "load")
    done()

navigationTest "following a same-origin data-turbolinks=true link inside a data-turbolinks=false container", (assert, session, done) ->
  session.clickSelector "#same-origin-true-link-inside-false-container", (navigation) ->
    assert.equal(navigation.location.pathname, "/fixtures/one.html")
    assert.equal(navigation.action, "push")
    done()

navigationTest "following a same-origin anchored link", (assert, session, done) ->
  session.clickSelector "#same-origin-anchored-link", (navigation) ->
    session.waitForEvent "turbolinks:load", ->
      assert.equal(navigation.location.pathname, "/fixtures/one.html")
      assert.equal(navigation.location.hash, "#element-id")
      assert.equal(navigation.action, "push")
      assert.scrolledTo(session.element.document.getElementById('element-id'))
      done()

navigationTest "following a same-origin link to named anchor", (assert, session, done) ->
  session.clickSelector "#same-origin-anchored-link-named", (navigation) ->
    session.waitForEvent "turbolinks:load", ->
      assert.equal(navigation.location.pathname, "/fixtures/one.html")
      assert.equal(navigation.location.hash, "#named-anchor")
      assert.equal(navigation.action, "push")
      assert.scrolledTo(session.element.document.querySelector('[name=named-anchor]'))
      done()

navigationTest "following a cross-origin unannotated link", (assert, session, done) ->
  session.clickSelector "#cross-origin-unannotated-link", (navigation) ->
    assert.equal(navigation.location, "about:blank")
    assert.equal(navigation.action, "load")
    done()

navigationTest "following a same-origin [target] link", (assert, session, done) ->
  session.clickSelector "#same-origin-targeted-link", (navigation) ->
    assert.equal(navigation.location.pathname, "/fixtures/one.html")
    assert.equal(navigation.action, "load")
    done()

navigationTest "following a same-origin [download] link", (assert, session, done) ->
  session.clickSelector "#same-origin-download-link", (navigation) ->
    assert.equal(navigation.location.pathname, "/fixtures/one.html")
    assert.equal(navigation.action, "load")
    done()

navigationTest "following a same-origin link inside an SVG element", (assert, session, done) ->
  session.clickSelector "#same-origin-link-inside-svg-element", (navigation) ->
    assert.equal(navigation.location.pathname, "/fixtures/one.html")
    assert.equal(navigation.action, "push")
    done()

navigationTest "following a cross-origin link inside an SVG element", (assert, session, done) ->
  session.clickSelector "#cross-origin-link-inside-svg-element", (navigation) ->
    assert.equal(navigation.location, "about:blank")
    assert.equal(navigation.action, "load")
    done()

navigationTest "clicking the back button", (assert, session, done) ->
  session.clickSelector "#same-origin-unannotated-link", ->
    session.waitForEvent "turbolinks:load", ->
      session.goBack (navigation) ->
        assert.equal(navigation.location.pathname, "/fixtures/navigation.html")
        assert.equal(navigation.action, "pop")
        done()

navigationTest "clicking the forward button", (assert, session, done) ->
  session.clickSelector "#same-origin-unannotated-link", ->
    session.waitForEvent "turbolinks:load", ->
      session.goBack ->
        session.goForward (navigation) ->
          assert.equal(navigation.location.pathname, "/fixtures/one.html")
          assert.equal(navigation.action, "pop")
          done()
