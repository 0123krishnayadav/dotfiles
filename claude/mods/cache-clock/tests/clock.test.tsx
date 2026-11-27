import { expect, test } from 'claude-code/testing'

const BAND = {
  plugin: 'cache-clock',
  component: 'AbovePrompt',
  requestId: 'band',
  props: { hasSurvey: false, isCollapsed: false, isWorking: false, maxRows: 3, bodyColumns: 120, scroll: { offset: 0, bodyRows: 3 } },
} as const

test('a turn starts the clock, and near expiry it pings to keep the cache warm', async ($, on) => {
  let now = 1_000_000
  let cost = 0
  let forks = 0

  on('command.register', () => ({ value: { command: 'cache-clock' } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('clock.now', () => ({ value: now }))
  // Each answered period runs the tick once and asks for the next period.
  on('clock.every', () => ({ value: {} }))
  on('agent.list', () => ({ value: [] }))
  on('session.usage', () => ({ value: { startedAt: 0, context: { window: 200_000 }, rateLimits: [], cost: { usd: cost } } }))
  on('store.get', () => ({ value: undefined }))
  on('store.set', () => ({ value: undefined }))
  on('model.fork', () => {
    forks += 1
    return { value: { isAnswered: true, text: 'ok', usage: { input_tokens: 40, output_tokens: 2, cache_read_input_tokens: 100_000, cache_creation_input_tokens: 0 } } }
  })
  on('turn.start', () => ({ turnId: 't1' }))
  on('turn.complete', () => ({ text: 'done' }))
  on('turn.step', async function* () {
    // $1 input: 100k written for 1h (2x) + 1k output (5x) => 205k units, so $1.025 at $5/M
    cost += 1.025
    return {
      turnId: 't1', index: 0, answer: 'hi', toolUses: [], stopReason: 'end_turn',
      usage: { model: 'claude-opus-5-5', input_tokens: 0, output_tokens: 1000, cache_read_input_tokens: 0,
        cache_creation_input_tokens: 100_000, ephemeral_5m_input_tokens: 0, ephemeral_1h_input_tokens: 100_000 },
    } as any
  })

  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  await $.turn.start({ turnId: 't1' } as any)
  const stream: any = $.turn.step({ turnId: 't1', index: 0, model: 'claude-opus-5-5', messageCount: 1 } as any)
  let step: any
  while (!(step = await stream.next()).done) {}
  const res = step.value
  await $.turn.complete({ answer: 'hi', durationMs: 1, isAborted: false, turnId: 't1', reason: 'answer' } as any)

  const status = await $.command.run({ command: 'cache-clock', args: 'status' } as any)
  expect((status as any).text).toContain('1h TTL')
  expect((status as any).text).toContain('$0.05 warm')

  // With most of the hour left, the row stays out of the way.
  let band = await $.ui.mount({ ...BAND, surface: 'terminal' })
  expect(await band.find({ type: 'Text', text: /cache/ })).toBeFalsy()
  await band.unmount()

  // Ten minutes left: the row shows the countdown and both prices.
  now += 50 * 60_000
  await new Promise(r => setTimeout(r, 50))
  band = await $.ui.mount({ ...BAND, surface: 'terminal' })
  expect(await band.find({ type: 'Text', text: /cache goes cold in 10m/ })).toBeTruthy()
  expect(await band.find({ type: 'Text', text: /reply now ≈ \$0\.05, later ≈ \$1\.01/ })).toBeTruthy()
  await band.unmount()
  expect(forks).toBe(0)

  // Two minutes left: keep-warm pings once.
  now += 8 * 60_000
  await new Promise(r => setTimeout(r, 50))
  expect(forks).toBe(1)
})
