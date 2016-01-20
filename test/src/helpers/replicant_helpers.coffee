@sessionTest = (name, callback) ->
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
