import intern from "intern"
import { Remote } from "intern/lib/executors/Node"
import { Tests } from "intern/lib/interfaces/object"

export class InternTestCase {
  readonly testName: string
  readonly remote: Remote

  static registerSuite() {
    return intern.getInterface("object").registerSuite(this.name, { tests: this.tests })
  }

  static get tests(): Tests {
    return this.testNames.reduce((tests, testName): Tests => {
      return { ...tests, [testName]: ({ remote }) => this.runTest(testName, remote) }
    }, {} as Tests)
  }

  static get testNames(): string[] {
    return this.testKeys.map(key => key.slice(5))
  }

  static get testKeys(): string[] {
    return Object.getOwnPropertyNames(this.prototype).filter(key => key.match(/^test /))
  }

  static runTest(testName: string, remote: Remote): Promise<void> {
    const testCase = new this(testName, remote)
    return testCase.runTest()
  }

  constructor(testName: string, remote: Remote) {
    this.testName = testName
    this.remote = remote
  }

  async runTest() {
    try {
      await this.setup()
      await this.beforeTest()
      await this.test()
      await this.afterTest()
    } finally {
      await this.teardown()
    }
  }

  get assert() {
    return intern.getPlugin("chai").assert
  }

  async setup() {

  }

  async beforeTest() {

  }

  get test(): () => Promise<void> {
    const method = (this as any)[`test ${this.testName}`]
    if (method != null && typeof method == "function") {
      return method
    } else {
      throw new Error(`No such test "${this.testName}"`)
    }
  }

  async afterTest() {

  }

  async teardown() {

  }
}
