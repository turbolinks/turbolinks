import { Remote } from "intern/lib/executors/Node"

export class RemoteChannel<T> {
  readonly remote: Remote
  readonly identifier: string
  private index: number = 0

  constructor(remote: Remote, identifier: string) {
    this.remote = remote
    this.identifier = identifier
  }

  async read(length?: number): Promise<T[]> {
    const records = (await this.newRecords).slice(0, length)
    this.index += records.length
    return records
  }

  async drain(): Promise<void> {
    await this.read()
  }

  private get newRecords(): Promise<T[]> {
    return this.remote.execute((identifier: string, index: number) => {
      const records = (window as any)[identifier]
      if (records != null && typeof records.slice == "function") {
        return records.slice(index)
      } else {
        return []
      }
    }, [this.identifier, this.index]) as any
  }
}
