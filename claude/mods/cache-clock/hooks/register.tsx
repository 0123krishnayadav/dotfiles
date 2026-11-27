import { atom, read, update } from 'claude-code'
import type { EngineInterface as Engine, Register, Timer, TurnUsage } from 'claude-code'

import type { Clock, ClockSettings, Ttl } from '../types'

const TICK_MS = 5000
// The band row appears once this little time is left on the cache.
const SHOW_WITHIN_MS = 15 * 60_000
const TTL_MS: Record<Ttl, number> = { '5m': 300_000, '1h': 3_600_000 }
// How long before expiry to warn the person, and to send a keep-warm ping.
const WARN_LEAD: Record<Ttl, number> = { '5m': 90_000, '1h': 360_000 }
const PING_LEAD: Record<Ttl, number> = { '5m': 60_000, '1h': 180_000 }
// Price multiples of a plain input token: cache writes, cache reads, output.
const WRITE_X: Record<Ttl, number> = { '5m': 1.25, '1h': 2 }
const READ_X = 0.1
const OUTPUT_X = 5

const PING_PROMPT =
  '[cache-clock keep-alive] Automated ping that only keeps the prompt cache warm. ' +
  'You have no tools. Do not think it over; reply with exactly: ok'

const YELLOW = '#facc15'
const RED = '#ef4444'

const EMPTY: Clock = {
  lastAt: null,
  ttl: null,
  contextTokens: 0,
  window: null,
  model: null,
  usdPerToken: null,
  isBusy: false,
  pings: 0,
  isCold: false,
  isWarned: false,
  ctxWarned: 0,
  now: 0,
  lastPingUsd: null,
}

const clock = atom({ plugin: 'cache-clock', key: 'clock' } as const, EMPTY, { shape: 'clock-1' })
const settings = atom({ plugin: 'cache-clock', key: 'settings' } as const, { isKeepWarm: true, maxPings: 3 } as ClockSettings, {
  shape: 'settings-1',
})

let timer: Timer | undefined
let isPinging = false

const tokens = (n: number) =>
  n >= 1_000_000 ? `${(n / 1_000_000).toFixed(1)}M` : n >= 1000 ? `${Math.round(n / 1000)}k` : `${n}`

const usd = (n: number) => (n < 0.01 ? '<$0.01' : `$${n.toFixed(2)}`)

const left = (ms: number) => {
  const s = Math.max(0, Math.ceil(ms / 1000))
  if (s >= 120) return `${Math.ceil(s / 60)}m`
  return `${s}s`
}

/** What the next message's re-sent context costs with the cache warm and cold. */
function prices(c: Clock) {
  if (c.usdPerToken === null) return null
  const ttl = c.ttl ?? '5m'

  return {
    warm: c.contextTokens * READ_X * c.usdPerToken,
    cold: c.contextTokens * WRITE_X[ttl] * c.usdPerToken,
  }
}

function ttlOf(u: TurnUsage, before: Ttl | null): Ttl | null {
  if ((u.ephemeral_1h_input_tokens ?? 0) > 0) return '1h'
  if ((u.ephemeral_5m_input_tokens ?? 0) > 0) return '5m'
  if (u.cache_creation_input_tokens > 0) return '5m'

  return before
}

async function spent($: Engine) {
  const [usage, agents] = await Promise.all([$.session.usage(), $.agent.list()])

  return {
    session: usage.cost?.usd ?? 0,
    agents: agents.reduce((n, a) => n + (a.cost?.usd ?? 0), 0),
    window: usage.context.window,
  }
}

async function readSettings($: Engine): Promise<ClockSettings> {
  const stored = (await $.store.get('settings')) as Partial<ClockSettings> | undefined

  return { isKeepWarm: stored?.isKeepWarm ?? true, maxPings: stored?.maxPings ?? 3 }
}

async function saveSettings($: Engine, next: ClockSettings) {
  await $.store.set('settings', next)
  await update($, settings, () => next)
}

/** Records a main-thread request: when it touched the cache, its size, and the price it implies. */
async function afterStep($: Engine, at: number, before: Awaited<ReturnType<typeof spent>>, u: TurnUsage) {
  const after = await spent($)
  const prev = await read($, clock)
  const ttl = ttlOf(u, prev.ttl)
  const touched = u.cache_read_input_tokens + u.cache_creation_input_tokens > 0
  const contextTokens = u.input_tokens + u.cache_read_input_tokens + u.cache_creation_input_tokens + u.output_tokens

  // The main thread's share of what the session was charged for this request,
  // over the tokens in plain-input units: an estimate of the input price.
  const cost = after.session - before.session - (after.agents - before.agents)
  const w5 = u.ephemeral_5m_input_tokens
  const w1 = u.ephemeral_1h_input_tokens
  const writeUnits =
    w5 !== undefined && w1 !== undefined
      ? w5 * WRITE_X['5m'] + w1 * WRITE_X['1h'] + Math.max(0, u.cache_creation_input_tokens - w5 - w1) * WRITE_X['5m']
      : u.cache_creation_input_tokens * WRITE_X[ttl ?? '5m']
  const units = u.input_tokens + writeUnits + u.cache_read_input_tokens * READ_X + u.output_tokens * OUTPUT_X
  const sample = cost > 0 && units > 0 ? cost / units : null
  const isSameModel = prev.model === u.model
  const usdPerToken =
    sample === null
      ? isSameModel
        ? prev.usdPerToken
        : null
      : isSameModel && prev.usdPerToken !== null
        ? prev.usdPerToken * 0.5 + sample * 0.5
        : sample

  const share = after.window > 0 ? (contextTokens / after.window) * 100 : 0
  const ctxWarned = share >= 80 ? 80 : share >= 50 ? 50 : prev.ctxWarned
  if (ctxWarned > prev.ctxWarned) {
    $.ui.toast(
      `Chat is getting expensive: ${tokens(contextTokens)} tokens (${Math.round(share)}% of the window) re-read every message. /compact or /clear when you change topic.`,
    )
  }

  await update($, clock, c => ({
    ...c,
    lastAt: touched ? at : c.lastAt,
    ttl,
    contextTokens,
    window: after.window,
    model: u.model,
    usdPerToken,
    isCold: touched ? false : c.isCold,
    isWarned: touched ? false : c.isWarned,
    ctxWarned,
    now: at,
  }))
}

/** Re-sends the cached conversation with a one-word question, which renews the cache entry. */
async function ping($: Engine, c: Clock) {
  isPinging = true
  try {
    const at = await $.clock.now()
    const before = (await $.session.usage()).cost?.usd ?? 0
    const r = await $.model.fork({ prompt: PING_PROMPT })
    const after = (await $.session.usage()).cost?.usd ?? 0

    if (!('usage' in r)) return

    const isHit = r.usage.cache_read_input_tokens >= c.contextTokens * 0.5
    if (!isHit) {
      await saveSettings($, { ...(await read($, settings)), isKeepWarm: false })
      $.ui.toast('Cache clock: the keep-warm ping missed the cache, so keep-warm is now off. /cache-clock on to retry.')
      await update($, clock, k => ({ ...k, pings: k.pings + 1, lastPingUsd: after - before }))

      return
    }

    await update($, clock, k => ({
      ...k,
      lastAt: at,
      pings: k.pings + 1,
      isCold: false,
      isWarned: false,
      now: at,
      lastPingUsd: after - before,
    }))
  } finally {
    isPinging = false
  }
}

async function tick($: Engine) {
  const c = await read($, clock)
  if (c.lastAt === null || c.ttl === null) return

  const now = await $.clock.now()
  const remaining = c.lastAt + TTL_MS[c.ttl] - now
  const s = await read($, settings)
  const cost = prices(c)
  const costs = cost ? ` Next message ≈ ${usd(cost.warm)} warm, ${usd(cost.cold)} cold.` : ''

  if (!c.isBusy) {
    if (remaining <= 0 && !c.isCold) {
      await update($, clock, k => ({ ...k, isCold: true, now }))
      $.ui.toast(`Prompt cache went cold: the next message re-caches ${tokens(c.contextTokens)} tokens.${costs}`)

      return
    }

    const canPing = s.isKeepWarm && c.pings < s.maxPings
    if (canPing && remaining > 0 && remaining <= PING_LEAD[c.ttl] && !isPinging) {
      void ping($, c)
    } else if (!canPing && remaining > 0 && remaining <= WARN_LEAD[c.ttl] && !c.isWarned) {
      await update($, clock, k => ({ ...k, isWarned: true, now }))
      const text = `Prompt cache goes cold in ${left(remaining)}: send your next message before then.${costs}`
      $.ui.toast(text)
      void $.ui.notify(text, { title: 'Cache clock' })
    }
  }

  // Redraw only when the countdown as shown would change.
  const bucket = (t: number) => {
    const r = c.lastAt! + TTL_MS[c.ttl!] - t

    return r >= 120_000 ? Math.ceil(r / 60_000) : Math.ceil(r / 10_000) * 10_000
  }
  if (bucket(now) !== bucket(c.now)) {
    await update($, clock, k => ({ ...k, now }))
  }
}

function start($: Engine) {
  timer ??= $.clock.every(TICK_MS, () => void tick($))
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    const stored = await readSettings($)
    await update($, settings, () => stored)
    await $.command.register({
      name: 'cache-clock',
      description: 'Prompt cache clock: on | off (keep-warm), pings <n>, status',
    })
    start($)

    return next(e)
  })

  on('turn.start', async ($, e, next) => {
    if (e.agentId === undefined) {
      await update($, clock, c => ({ ...c, isBusy: true, pings: 0 }))
    }

    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    const done = await next(e)
    if (e.agentId === undefined) {
      const now = await $.clock.now()
      await update($, clock, c => ({ ...c, isBusy: false, now }))
    }

    return done
  })

  on('turn.step', async function* ($, e, next) {
    if (e.agentId !== undefined) {
      return yield* next(e)
    }

    const at = await $.clock.now()
    const before = await spent($)
    const result = yield* next(e)
    if (result.usage) {
      await afterStep($, at, before, result.usage)
    }

    return result
  })

  on('command.run', { command: 'cache-clock' }, async ($, e) => {
    const [word, arg] = e.args.trim().split(/\s+/)
    const s = await read($, settings)

    if (word === 'on' || word === 'off') {
      await saveSettings($, { ...s, isKeepWarm: word === 'on' })

      return { text: `Cache clock keep-warm ${word}.` }
    }

    if (word === 'pings') {
      const n = Number(arg)
      if (!Number.isInteger(n) || n < 0 || n > 24) return { text: 'Usage: /cache-clock pings <0-24>' }
      await saveSettings($, { ...s, maxPings: n })

      return { text: `Cache clock will send at most ${n} keep-warm pings while you are away.` }
    }

    const c = await read($, clock)
    const now = await $.clock.now()
    const cost = prices(c)
    const lines = [
      c.lastAt === null || c.ttl === null
        ? 'No cached request yet.'
        : `Cache ${c.isCold ? 'cold' : 'warm'} (${c.ttl} TTL), ${left(c.lastAt + TTL_MS[c.ttl] - now)} left.`,
      `Context ${tokens(c.contextTokens)} tokens${c.window ? ` of ${tokens(c.window)}` : ''} on ${c.model ?? '?'}.`,
      cost ? `Next message ≈ ${usd(cost.warm)} warm, ${usd(cost.cold)} cold (estimate).` : 'Cost: no estimate yet.',
      `Keep-warm ${s.isKeepWarm ? 'on' : 'off'}, ${c.pings}/${s.maxPings} pings used${c.lastPingUsd !== null ? `, last ${usd(c.lastPingUsd)}` : ''}.`,
    ]

    return { text: lines.join('\n') }
  })

  // The row shows only while it matters: idle, with the cache's last minutes running down.
  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    if (e.props.hasSurvey) return next(e)

    const [c, s] = await Promise.all([read($, clock), read($, settings)])
    if (c.lastAt === null || c.ttl === null || c.isBusy || c.isCold) return next(e)

    const remaining = c.lastAt + TTL_MS[c.ttl] - c.now
    if (remaining <= 0 || remaining > SHOW_WITHIN_MS) return next(e)

    const { Box, Button, Text } = $.ui.resolve(e)
    const cost = prices(c)
    const isWide = e.props.bodyColumns >= 90
    const color = remaining <= WARN_LEAD[c.ttl] ? RED : YELLOW

    return (
      <Box>
        <Text color={color} bold>
          ⏱ cache goes cold in {left(remaining)}
        </Text>
        <Text dimColor>
          {' '}
          · ctx {tokens(c.contextTokens)}
          {cost ? ` · reply now ≈ ${usd(cost.warm)}, later ≈ ${usd(cost.cold)}` : ''}
          {isWide && s.isKeepWarm && c.pings < s.maxPings ? ' · keep-warm will ping' : ''}{' '}
        </Text>
        <Button
          key="keep"
          plain
          label={s.isKeepWarm ? `keep-warm ${c.pings}/${s.maxPings}` : 'keep-warm off'}
          onPress={() => saveSettings($, { ...s, isKeepWarm: !s.isKeepWarm })}
        />
      </Box>
    )
  })
}
