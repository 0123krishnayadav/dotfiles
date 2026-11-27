import type { EngineInterface as Engine, Register } from 'claude-code'

const DEFAULT_LIMIT = 256_000
const RETRY_MS = 1500
const RETRIES = 5

type Config = { isOn: boolean; limit: number }

// Turn ids already compacted after, so one turn never compacts twice.
let lastTurnId: string | undefined
let isCompacting = false

const tokens = (n: number) => (n >= 1_000_000 ? `${+(n / 1_000_000).toFixed(2)}M` : `${Math.round(n / 1000)}k`)

/** "256k", "1.5m", "300000" → tokens; null when it is none of those. */
function parseTokens(text: string): number | null {
  const m = /^(\d+(?:\.\d+)?)\s*([km]?)$/i.exec(text.trim())
  if (!m) return null
  const scale = { '': 1, k: 1000, m: 1_000_000 }[m[2]!.toLowerCase() as '' | 'k' | 'm']
  const n = Math.round(Number(m[1]) * scale)

  return n >= 10_000 ? n : null
}

async function readConfig($: Engine): Promise<Config> {
  const stored = (await $.store.get('config')) as Partial<Config> | undefined

  return { isOn: stored?.isOn ?? true, limit: stored?.limit ?? DEFAULT_LIMIT }
}

async function compact($: Engine, before: number, limit: number, attempt: number) {
  try {
    const result = await $.session.compact()
    isCompacting = false
    if (result.skip !== undefined) {
      $.ui.toast(`compact-at: compaction skipped (${result.skip})`)

      return
    }
    const after = result.tokensAfter
    $.ui.toast(
      `Auto-compacted at ${tokens(before)} (limit ${tokens(limit)})${after !== undefined ? ` → ${tokens(after)}` : ''}.`,
    )
  } catch (error) {
    // It rejects while a turn runs: the person may have sent the next prompt
    // already, or the turn is still winding down. Try again shortly.
    if (attempt < RETRIES) {
      $.clock.after(RETRY_MS, () => void compact($, before, limit, attempt + 1))

      return
    }
    isCompacting = false
    $.ui.toast(`compact-at: could not compact at ${tokens(before)}: ${String(error).slice(0, 120)}. Run /compact.`)
  }
}

async function check($: Engine, turnId: string) {
  const config = await readConfig($)
  if (!config.isOn || isCompacting || lastTurnId === turnId) return

  const { context } = await $.session.usage()
  const used = context.tokens ?? 0
  if (used < config.limit) return

  lastTurnId = turnId
  isCompacting = true
  $.clock.after(250, () => void compact($, used, config.limit, 0))
}

async function status($: Engine) {
  const config = await readConfig($)
  const { context } = await $.session.usage()
  const used = context.tokens ?? 0

  return (
    `Auto-compact ${config.isOn ? 'on' : 'off'} at ${tokens(config.limit)} tokens. ` +
    `Context now ${tokens(used)} of a ${tokens(context.window)} window.`
  )
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'compact-at',
      description: 'Auto-compact limit: /compact-at 256k | on | off (no argument: status)',
    })

    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    const done = await next(e)
    if (e.agentId === undefined) {
      await check($, e.turnId)
    }

    return done
  })

  on('command.run', { command: 'compact-at' }, async ($, e) => {
    const arg = e.args.trim().toLowerCase()
    const config = await readConfig($)

    if (arg === 'on' || arg === 'off') {
      await $.store.set('config', { ...config, isOn: arg === 'on' })

      return { text: await status($) }
    }

    if (arg !== '' && arg !== 'status') {
      const limit = parseTokens(arg)
      if (limit === null) return { text: 'Usage: /compact-at 256k | 1m | on | off' }
      await $.store.set('config', { isOn: true, limit })
    }

    return { text: await status($) }
  })
}
