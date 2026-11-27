import { expect, test } from 'claude-code/testing'

const turn = (turnId: string, agentId?: string) =>
  ({ answer: 'ok', durationMs: 1, isAborted: false, turnId, reason: 'answer', ...(agentId ? { agentId } : {}) }) as any

test('compacts once the main context reaches 256k, and only then', async ($, on) => {
  let used = 200_000
  let compactions = 0
  const store = new Map<string, unknown>()

  on('command.register', () => ({ value: { command: 'compact-at' } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('store.get', (_, e: any) => ({ value: store.get(e.key) }))
  on('store.set', (_, e: any) => (store.set(e.key, e.value), { value: undefined }))
  on('session.usage', () => ({ value: { startedAt: 0, context: { tokens: used, window: 1_000_000 }, rateLimits: [] } }))
  on('session.messages', () => ({ value: [{ role: 'user', text: 'hi' }] }))
  on('clock.after', () => ({ value: {} }))
  on('turn.complete', () => ({ text: 'ok' }))
  const toasts: string[] = []
  on('ui.toast', (_, e: any) => (toasts.push(String(e.text ?? '')), { value: undefined }))
  // In a real session the engine fills in the transcript; this stands for core's compaction.
  on('session.compact', () => {
    compactions += 1
    return { messages: [{ role: 'user', text: 'summary', toolUses: [] }], tokensBefore: used, tokensAfter: 30_000 }
  })

  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })

  await $.turn.complete(turn('t1'))
  await new Promise(r => setTimeout(r, 30))
  expect(compactions).toBe(0)

  used = 260_000
  await $.turn.complete(turn('t2', 'sub-agent'))
  await new Promise(r => setTimeout(r, 30))
  expect(compactions).toBe(0)

  await $.turn.complete(turn('t2'))
  await $.turn.complete(turn('t2'))
  await new Promise(r => setTimeout(r, 30))
  expect(compactions).toBe(1)
  expect(toasts.join(' ')).toContain('Auto-compacted at 260k (limit 256k) → 30k')

  const off = await $.command.run({ command: 'compact-at', args: 'off' } as any)
  expect((off as any).text).toContain('Auto-compact off at 256k')
  await $.turn.complete(turn('t3'))
  await new Promise(r => setTimeout(r, 30))
  expect(compactions).toBe(1)

  const set = await $.command.run({ command: 'compact-at', args: '300k' } as any)
  expect((set as any).text).toContain('on at 300k')
  await $.turn.complete(turn('t4'))
  await new Promise(r => setTimeout(r, 30))
  expect(compactions).toBe(1)
})
