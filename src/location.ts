export type Locatable = Location | string

export class Location {
  static wrap(locatable: Locatable): Location
  static wrap(locatable?: Locatable | null): Location | undefined
  static wrap(locatable: Locatable) {
    if (typeof locatable == "string") {
      return new this(locatable)
    } else if (locatable != null) {
      return locatable
    }
  }

  readonly absoluteURL: string
  readonly requestURL: string
  readonly anchor?: string

  constructor(url: string) {
    const linkWithAnchor = document.createElement("a")
    linkWithAnchor.href = url

    this.absoluteURL = linkWithAnchor.href

    const anchorLength = linkWithAnchor.hash.length
    if (anchorLength < 2) {
      this.requestURL = this.absoluteURL
    } else {
      this.requestURL = this.absoluteURL.slice(0, -anchorLength)
      this.anchor = linkWithAnchor.hash.slice(1)
    }
  }

  getOrigin() {
    return this.absoluteURL.split("/", 3).join("/")
  }

  getPath() {
    return (this.requestURL.match(/\/\/[^/]*(\/[^?;]*)/) || [])[1] || "/"
  }

  getPathComponents() {
    return this.getPath().split("/").slice(1)
  }

  getLastPathComponent() {
    return this.getPathComponents().slice(-1)[0]
  }

  getExtension() {
    return (this.getLastPathComponent().match(/\.[^.]*$/) || [])[0] || ""
  }

  isHTML() {
    return this.getExtension().match(/^(?:|\.(?:htm|html|xhtml))$/)
  }

  isPrefixedBy(location: Location): boolean {
    const prefixURL = getPrefixURL(location)
    return this.isEqualTo(location) || stringStartsWith(this.absoluteURL, prefixURL)
  }

  isEqualTo(location?: Location) {
    return location && this.absoluteURL === location.absoluteURL
  }

  toCacheKey() {
    return this.requestURL
  }

  toJSON() {
    return this.absoluteURL
  }

  toString() {
    return this.absoluteURL
  }

  valueOf() {
    return this.absoluteURL
  }
}

function getPrefixURL(location: Location) {
  return addTrailingSlash(location.getOrigin() + location.getPath())
}

function addTrailingSlash(url: string) {
  return stringEndsWith(url, "/") ? url : url + "/"
}

function stringStartsWith(string: string, prefix: string) {
  return string.slice(0, prefix.length) === prefix
}

function stringEndsWith(string: string, suffix: string) {
  return string.slice(-suffix.length) === suffix
}
