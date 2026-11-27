export type AgentRow = {
  id: string
  description: string
  type: string
  status: string
  label: string
  parentId?: string
  model?: string
  startTime: number
  endTime?: number
  contextTokens: number
  contextWindow?: number
  inputTokens: number
  outputTokens: number
  costUsd?: number
}

export type Snapshot = {
  at: number
  agents: AgentRow[]
  sessionCostUsd?: number
}

declare module 'claude-code' {
  interface PluginState {
    'helper-desk': { snap: Shaped<Snapshot>; isBandHidden: boolean }
  }
}
