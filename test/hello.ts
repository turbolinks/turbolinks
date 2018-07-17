import intern from "intern"
const { assert } = intern.getPlugin("chai")
const { registerSuite } = intern.getInterface("object")

registerSuite("Hello", {
  async "loading a page"() {
    await this.remote.get("http://localhost:9000/test/fixtures/hello.html")
    assert.equal("Hello World", await this.remote.getPageTitle())
  }
})
