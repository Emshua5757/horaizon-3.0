export class SduiStateVault {
  // Key-value store of Node ID -> Any Value
  private state: Map<string, any> = new Map();

  constructor() {}

  public get(id: string): any {
    return this.state.get(id);
  }

  public set(id: string, value: any): void {
    this.state.set(id, value);
  }

  public dump(): Record<string, any> {
    return Object.fromEntries(this.state);
  }

  public clear(): void {
    this.state.clear();
  }
}
