export type Ttl = '5m' | '1h'

export type Clock = {
  /** When the main thread's last request that read or wrote the cache began. */
  lastAt: number | null
  ttl: Ttl | null
  /** Tokens the next request re-sends (the last main request's input + output). */
  contextTokens: number
  window: number | null
  model: string | null
  /** Estimated USD per plain input token, learnt from the session's own cost. */
  usdPerToken: number | null
  isBusy: boolean
  /** Keep-warm pings sent since the last turn. */
  pings: number
  isCold: boolean
  isWarned: boolean
  /** The highest share of the context window already warned about (0, 50, 80). */
  ctxWarned: number
  /** The display clock: moves when the shown countdown would change. */
  now: number
  lastPingUsd: number | null
}

export type ClockSettings = { isKeepWarm: boolean; maxPings: number }

declare module 'claude-code' {
  interface PluginState {
    'cache-clock': { clock: Shaped<Clock>; settings: Shaped<ClockSettings> }
  }
}
