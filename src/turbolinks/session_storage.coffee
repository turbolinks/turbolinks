class Turbolinks.SessionStorage
  set: (key, value) ->
    window.sessionStorage.setItem(key, JSON.stringify(value))

  get: (key) ->
    JSON.parse(window.sessionStorage.getItem(key))

  remove: (key) ->
    window.sessionStorage.removeItem(key)
