import assert from 'node:assert/strict';
import { existsSync } from 'node:fs';
import { resolve } from 'node:path';
import test from 'node:test';
import { read } from './design_audit.mjs';

test('capability audit preserves section 26 gaps and resolvable local evidence', () => {
  const report = read('docs/phase_7h4_capability_audit.md');
  for (const requirement of ['显示剩余时间', '恢复未过期定时', '到期平滑暂停', '系统设置入口', '无缝播放', '音量标准化', '播放结束后继续']) {
    assert(report.includes(requirement), requirement);
  }
  for (const [, link] of report.matchAll(/\]\(([^)]+)\)/g)) {
    if (!link.includes('://')) assert(existsSync(resolve('docs', link)), link);
  }
  assert(report.includes('session-only'));
  assert(report.includes('不得据这些返回值宣称Windows标准化生效'));
});
