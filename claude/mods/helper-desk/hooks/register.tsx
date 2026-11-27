import { atom, read, update } from 'claude-code'
import type { AgentInfo, EngineInterface as Engine, Register, Timer } from 'claude-code'

import type { AgentRow, Snapshot } from '../types'

const PANE = 'helper-desk'
const TITLE = 'Helper Desk'
const POLL_MS = 2000
// How long the panel stays after the last subagent finishes, when it opened by itself.
const LINGER_MS = 20_000

const PURPLE = '#6d28d9'
const LAVENDER = '#c4b5fd'
const WHITE = '#ffffff'

const snap = atom({ plugin: 'helper-desk', key: 'snap' } as const, { at: 0, agents: [] } as Snapshot, {
  shape: 'snap-1',
})
const isBandHidden = atom({ plugin: 'helper-desk', key: 'isBandHidden' } as const, false)

const FINAL = new Set(['completed', 'failed', 'killed'])
const ACTIVE = new Set(['pending', 'running', 'waiting'])

const GLYPH: Record<string, string> = {
  pending: '○',
  running: '●',
  waiting: '◐',
  idle: '◌',
  completed: '✓',
  failed: '✗',
  killed: '■',
}

const COLOR: Record<string, string> = {
  pending: '#a1a1aa',
  running: '#a78bfa',
  waiting: '#facc15',
  idle: '#93c5fd',
  completed: '#22c55e',
  failed: '#ef4444',
  killed: '#a1a1aa',
}

const tokens = (n: number) =>
  n >= 1_000_000 ? `${(n / 1_000_000).toFixed(1)}M` : n >= 1000 ? `${(n / 1000).toFixed(1)}k` : `${n}`

const usd = (n: number | undefined) => (n === undefined ? '–' : n < 0.01 && n > 0 ? '<$0.01' : `$${n.toFixed(2)}`)

const elapsed = (ms: number) => {
  const s = Math.max(0, Math.round(ms / 1000))
  if (s < 60) return `${s}s`
  const m = Math.floor(s / 60)
  if (m < 60) return `${m}m${String(s % 60).padStart(2, '0')}s`
  return `${Math.floor(m / 60)}h${String(m % 60).padStart(2, '0')}m`
}

const firstLine = (text: string) => text.split('\n').find(line => line.trim() !== '')?.trim() ?? ''

function toRow(agent: AgentInfo, before: AgentRow | undefined, now: number): AgentRow {
  const usage = agent.usage ?? []
  const isFinal = FINAL.has(agent.status)

  return {
    id: agent.id,
    description: agent.description,
    type: agent.type,
    status: agent.status,
    label: agent.label,
    parentId: agent.parentId,
    model: agent.model,
    startTime: agent.startTime,
    endTime: isFinal ? (before?.endTime ?? now) : undefined,
    contextTokens: agent.tokenCount,
    contextWindow: agent.contextWindowSize,
    inputTokens: usage.reduce(
      (n, u) => n + u.input_tokens + (u.cache_read_input_tokens ?? 0) + (u.cache_creation_input_tokens ?? 0),
      0,
    ),
    outputTokens: usage.reduce((n, u) => n + u.output_tokens, 0),
    costUsd: agent.cost?.usd,
  }
}

function totals(agents: AgentRow[]) {
  const count = (pred: (a: AgentRow) => boolean) => agents.filter(pred).length

  return {
    active: count(a => ACTIVE.has(a.status)),
    idle: count(a => a.status === 'idle'),
    done: count(a => a.status === 'completed'),
    failed: count(a => a.status === 'failed' || a.status === 'killed'),
    tokens: agents.reduce((n, a) => n + a.inputTokens + a.outputTokens, 0),
    cost: agents.reduce((n, a) => n + (a.costUsd ?? 0), 0),
  }
}

let timer: Timer | undefined
// The panel opened by itself for running subagents (closed again when they finish),
// or the person opened it with /helper-desk (left for them to close).
let isAutoOpened = false
let isPersonOpened = false

const isActive = (a: AgentRow) => !FINAL.has(a.status) && a.status !== 'idle'

// Reads every agent and the session cost, and writes only when something
// changed beyond the clock (or an agent is still running, so elapsed times
// tick), so drawings redraw for real news.
async function refresh($: Engine) {
  const [list, usage, now, prev] = await Promise.all([
    $.agent.list(),
    $.session.usage(),
    $.clock.now(),
    read($, snap),
  ])
  const byId = new Map(prev.agents.map(a => [a.id, a]))
  const agents = list.map(agent => toRow(agent, byId.get(agent.id), now))
  const isAnyActive = agents.some(isActive)
  const wasAnyActive = prev.agents.some(isActive)
  const fresh: Snapshot = { at: now, agents, sessionCostUsd: usage.cost?.usd }
  const isSame = JSON.stringify({ ...prev, at: 0 }) === JSON.stringify({ ...fresh, at: 0 })

  if (!isSame || isAnyActive) {
    await update($, snap, () => fresh)
  }

  if (!isAnyActive && timer) {
    timer.cancel()
    timer = undefined
  }

  if (wasAnyActive && !isAnyActive && isAutoOpened) {
    $.clock.after(LINGER_MS, () => void closeIfDone($))
  }
}

async function closeIfDone($: Engine) {
  const { agents } = await read($, snap)
  if (agents.some(isActive) || !isAutoOpened || isPersonOpened) return
  isAutoOpened = false
  await $.ui.close({ id: PANE })
}

function kick($: Engine) {
  void refresh($)
  timer ??= $.clock.every(POLL_MS, () => void refresh($))
}

function openPane($: Engine) {
  return $.ui.open({ id: PANE, title: TITLE })
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'helper-desk',
      description: 'Open the Helper Desk panel: every subagent with its progress, tokens and cost',
    })
    kick($)

    return next(e)
  })

  on('command.run', { command: 'helper-desk' }, async $ => {
    await update($, isBandHidden, () => false)
    isPersonOpened = true
    kick($)
    await openPane($)

    return { text: 'Helper Desk opened.' }
  })

  on('agent.spawn', async ($, e, next) => {
    const started = await next(e)
    if (!isPersonOpened) {
      isAutoOpened = true
      void openPane($)
    }
    kick($)

    return started
  })

  on('ui.close', async ($, e, next) => {
    if (e.id === PANE) {
      isAutoOpened = false
      isPersonOpened = false
    }

    return next(e)
  })

  on('turn.complete', async ($, e, next) => {
    const done = await next(e)
    kick($)

    return done
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const [{ agents, sessionCostUsd }, isHidden] = await Promise.all([read($, snap), read($, isBandHidden)])

    const t = totals(agents)

    if (e.props.hasSurvey || isHidden || t.active === 0) {
      return next(e)
    }

    const { Box, Button, Text } = $.ui.resolve(e)
    const isWide = e.props.bodyColumns >= 90

    return (
      <Box backgroundColor={PURPLE} paddingX={1} width="100%">
        <Text color={WHITE} bold>
          ◆ Helper Desk{' '}
        </Text>
        <Text color={WHITE}>
          <Text color="#fde68a">● {t.active} running</Text>
          {t.idle > 0 ? `  ◌ ${t.idle} idle` : ''}
          <Text color="#86efac">{`  ✓ ${t.done} done`}</Text>
          {t.failed > 0 ? <Text color="#fca5a5">{`  ✗ ${t.failed} failed`}</Text> : ''}
          {isWide ? `  │ ${tokens(t.tokens)} tok  │ agents ${usd(t.cost)} ` : ' '}
        </Text>
        {isWide && <Text color={LAVENDER}>│ session {usd(sessionCostUsd)} </Text>}
        <Button key="open" label="Panel" plain onPress={() => openPane($)} />
        <Text> </Text>
        <Button key="hide" label="×" plain onPress={() => update($, isBandHidden, () => true)} />
      </Box>
    )
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Text, Progress } = $.ui.resolve(e)
    const { agents, at, sessionCostUsd } = await read($, snap)
    const t = totals(agents)
    const width = e.props.bodyColumns

    // Running ones first, then the newest.
    const order = (a: AgentRow) => (ACTIVE.has(a.status) ? 0 : a.status === 'idle' ? 1 : 2)
    const sorted = [...agents].sort((a, b) => order(a) - order(b) || b.startTime - a.startTime)

    if (e.props.placement === 'widget') {
      return (
        <Box flexDirection="column">
          <Text color={PURPLE} bold>
            ● {t.active} running · ✓ {t.done} · {usd(t.cost)}
          </Text>
        </Box>
      )
    }

    return (
      <Box flexDirection="column" gap={1}>
        <Box flexDirection="column" borderStyle="round" borderColor={PURPLE} paddingX={1}>
          <Text color={PURPLE} bold>
            Overall
          </Text>
          <Text>
            <Text color={COLOR.running}>● {t.active} running</Text>
            {'  '}
            <Text color={COLOR.idle}>◌ {t.idle} idle</Text>
            {'  '}
            <Text color={COLOR.completed}>✓ {t.done} done</Text>
            {'  '}
            <Text color={COLOR.failed}>✗ {t.failed} failed</Text>
          </Text>
          <Text dimColor>
            {tokens(t.tokens)} tokens · agents {usd(t.cost)} · session {usd(sessionCostUsd)}
          </Text>
        </Box>

        {sorted.length === 0 && <Text dimColor>No subagents in this session yet.</Text>}

        {sorted.map(agent => {
          const color = COLOR[agent.status] ?? LAVENDER
          const end = agent.endTime ?? at
          const summary = firstLine(agent.label)
          const isDescriptionOnly = summary === agent.description.trim()

          return (
            <Box key={agent.id} flexDirection="column" borderStyle="single" borderColor={color} paddingX={1}>
              <Text>
                <Text color={color} bold>
                  {GLYPH[agent.status] ?? '?'} {agent.description || agent.type}
                </Text>
                <Text dimColor>
                  {'  '}
                  {agent.type} · {agent.status} · {elapsed(end - agent.startTime)}
                  {agent.parentId ? ' · nested' : ''}
                </Text>
              </Text>
              {!isDescriptionOnly && summary !== '' && (
                <Text maxLines={2} italic>
                  {summary}
                </Text>
              )}
              {agent.contextWindow ? (
                <Progress
                  label="context"
                  value={agent.contextTokens}
                  max={agent.contextWindow}
                  valueText={`${tokens(agent.contextTokens)} / ${tokens(agent.contextWindow)}`}
                  color={color}
                />
              ) : null}
              <Text dimColor>
                {agent.model ?? 'model ?'} · in {tokens(agent.inputTokens)} · out {tokens(agent.outputTokens)} ·{' '}
                {usd(agent.costUsd)}
              </Text>
            </Box>
          )
        })}
        {width < 40 && <Text dimColor>(widen the panel for more)</Text>}
      </Box>
    )
  })
}
