import { expect, test } from 'claude-code/testing'

const PANE = {
  plugin: 'helper-desk',
  component: 'Pane',
  requestId: 'helper-desk',
  props: {
    title: 'Helper Desk',
    isFocused: false,
    bodyColumns: 60,
    placement: 'dock',
    scroll: { offset: 0, bodyRows: 30 },
    view: {},
  },
} as const

const BAND = {
  plugin: 'helper-desk',
  component: 'AbovePrompt',
  requestId: 'band',
  props: {
    hasSurvey: false,
    isCollapsed: false,
    isWorking: true,
    maxRows: 3,
    bodyColumns: 120,
    scroll: { offset: 0, bodyRows: 3 },
  },
} as const

const agent = (id: string, status: string, extra: object = {}) => ({
  id,
  description: `task ${id}`,
  type: 'Explore',
  status,
  kind: 'local_agent',
  taskStatus: status === 'completed' ? 'completed' : 'running',
  label: `reading files for ${id}`,
  startTime: 1_000,
  cwd: '/',
  model: 'claude-haiku-5-5',
  contextWindowSize: 200_000,
  tokenCount: 50_000,
  tokenSamples: [],
  usage: [{ input_tokens: 1000, output_tokens: 2000, cache_read_input_tokens: 40_000, cache_creation_input_tokens: 0 }],
  cost: { usd: 0.12 },
  hasRow: true,
  ...extra,
})

test('the band stays hidden while no subagent runs', async ($, on) => {
  on('command.register', () => ({ value: { command: 'helper-desk' } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('agent.list', () => ({ value: [agent('b', 'completed')] }))
  on('session.usage', () => ({ value: { startedAt: 0, context: {}, rateLimits: [], cost: { usd: 1 } } }))
  on('clock.now', () => ({ value: 31_000 }))
  on('clock.every', () => ({ value: {} }))

  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  await new Promise(r => setTimeout(r, 30))

  const band = await $.ui.mount({ ...BAND, surface: 'terminal' })
  expect(await band.find({ type: 'Text', text: /Helper Desk/ })).toBeFalsy()
  await band.unmount()
})

test('band and pane show every subagent with its tokens and cost', async ($, on) => {
  on('command.register', () => ({ value: { command: 'helper-desk' } }))
  on('ui.open', () => ({ value: { isPlaced: true } }))
  on('session.start', (_, e) => ({ cwd: e.cwd }))
  on('agent.list', () => ({ value: [agent('a', 'running'), agent('b', 'completed'), agent('c', 'failed')] }))
  on('session.usage', () => ({ value: { startedAt: 0, context: {}, rateLimits: [], cost: { usd: 1.5 } } }))
  on('clock.now', () => ({ value: 31_000 }))
  on('clock.every', () => ({ value: { cancel: () => {} } }))

  await $.session.start({ cwd: '/', surface: 'terminal', isInteractive: true })
  await $.command.run({ command: 'helper-desk', args: '' })

  const band = await $.ui.mount({ ...BAND, surface: 'terminal' })
  expect((await band.find({ type: 'Text', text: /1 running/ }))?.text).toContain('1 running')
  expect((await band.find({ type: 'Text', text: /session \$1\.50/ }))).toBeTruthy()
  await band.unmount()

  const pane = await $.ui.mount({ ...PANE, surface: 'terminal' })
  expect(await pane.find({ type: 'Text', text: /task a/ })).toBeTruthy()
  expect(await pane.find({ type: 'Text', text: /30s/ })).toBeTruthy()
  expect(await pane.find({ type: 'Text', text: /in 41\.0k · out 2\.0k/ })).toBeTruthy()
  expect(await pane.find({ type: 'Text', text: /1 failed/ })).toBeTruthy()
  await pane.unmount()
})
