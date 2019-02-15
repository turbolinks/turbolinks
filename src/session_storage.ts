export class SessionStorage {
  set(key:string, value:any) {
    window.sessionStorage.setItem(key, JSON.stringify(value))
  }

  get(key:string) {
    return JSON.parse(window.sessionStorage.getItem(key) || 'null')
  }

  remove(key:string) {
    window.sessionStorage.removeItem(key)
  }
}
