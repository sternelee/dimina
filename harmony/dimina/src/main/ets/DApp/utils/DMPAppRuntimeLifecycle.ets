export enum DMPAppRuntimePhase {
  READY,
  CLOSING,
  DESTROYED,
}

/**
 * Tracks the transient runtime owned by one DMPApp shell.
 *
 * A host may retain the DMPApp object after closing it. The object identity and app-level
 * configuration survive, but its Worker, render/container graph and native listeners do not.
 */
export class DMPAppRuntimeLifecycle {
  private phase: DMPAppRuntimePhase = DMPAppRuntimePhase.READY

  get isClosing(): boolean {
    return this.phase === DMPAppRuntimePhase.CLOSING
  }

  get isDestroyed(): boolean {
    return this.phase === DMPAppRuntimePhase.DESTROYED
  }

  beginClose(): boolean {
    if (this.phase !== DMPAppRuntimePhase.READY) {
      return false
    }
    this.phase = DMPAppRuntimePhase.CLOSING
    return true
  }

  cancelClose(): void {
    if (this.phase === DMPAppRuntimePhase.CLOSING) {
      this.phase = DMPAppRuntimePhase.READY
    }
  }

  markDestroyed(): void {
    this.phase = DMPAppRuntimePhase.DESTROYED
  }

  markReady(): void {
    this.phase = DMPAppRuntimePhase.READY
  }

  shouldDeferLaunch(): boolean {
    return this.phase === DMPAppRuntimePhase.CLOSING
  }
}
