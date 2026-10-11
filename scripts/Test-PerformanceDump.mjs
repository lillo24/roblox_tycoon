// Optional offline regression against the retained PERF-03 captures. Extract
// docs/perf-03/native-captures.zip first; this never opens Studio or a network.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const [calibrationPath, naturalPath] = process.argv.slice(2);
if (!calibrationPath || !naturalPath) {
  throw new Error('Usage: node scripts/Test-PerformanceDump.mjs <calibration.html> <natural-3-first.html>');
}
const reader = fileURLToPath(new URL('./Read-PerformanceDump.mjs', import.meta.url));
const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'perf03-reader-'));
try {
  const read = (input, name) => {
    const output = path.join(temporary, name + '.json');
    const result = spawnSync(process.execPath, [reader, input, output], { encoding: 'utf8' });
    assert.equal(result.status, 0, `${input}: ${result.error?.message ?? result.stderr}`);
    return JSON.parse(fs.readFileSync(output, 'utf8'));
  };
  const calibration = read(calibrationPath, 'calibration');
  const stall = calibration.fixtureEvents.find(x => x.name === 'PERF03 deliberate calibration stall');
  const marker = calibration.fixtureEvents.find(x => x.name === 'PERF03 slow interval observed');
  assert.ok(stall?.ms >= 99 && stall.ms < 110, 'Known 100 ms calibration must survive native decoding');
  assert.ok(marker && marker.start > stall.end, 'Following marker must not be confused with stall work');
  assert.ok(stall.frame > 0 && marker.frame < calibration.frameCount - 1, 'Retain preceding and following frames');

  const natural = read(naturalPath, 'natural');
  assert.ok(natural.above50 > 0 && natural.worst.intervalMs > 50, 'Natural export must contain a retained hitch');
  assert.ok(!natural.fixtureEvents.some(x => /^PERF03 /.test(x.name)), 'Missed original one-shot marker must stay absent');
  assert.ok(natural.fixtureEvents.filter(x => x.name === 'PERF02 slow interval end').length > 1,
    'Retained marker sequence is needed for alignment to deferred probe records');
  for (const summary of [calibration, natural]) {
    assert.ok(!summary.fixtureEvents.some(x => /^Script_/.test(x.name)),
      'An engine script name is not a fixed calibration/signal event');
    assert.equal(summary.slowFrameOverlaps.length, summary.above50);
    const worst = summary.slowFrameOverlaps.find(x => x.frame.index === summary.worst.index);
    assert.deepEqual(worst.scopes, summary.worstOverlap, 'Existing worstOverlap output remains compatible');
  }

  const truncated = path.join(temporary, 'truncated.html');
  fs.writeFileSync(truncated, fs.readFileSync(calibrationPath).subarray(0, 256));
  const failed = spawnSync(process.execPath, [reader, truncated, path.join(temporary, 'invalid.json')]);
  assert.notEqual(failed.status, 0, 'Truncated capture must fail explicitly');
  assert.ok(!fs.existsSync(path.join(temporary, 'invalid.json')), 'Failure must not emit a valid-looking summary');
  console.log('PERF-03 native reader regression passed: calibration, natural hitch context, marker selection, compatibility and truncated-input failure.');
} finally {
  assert.equal(path.dirname(fs.realpathSync(temporary)), fs.realpathSync(os.tmpdir()));
  assert.ok(path.basename(temporary).startsWith('perf03-reader-'));
  fs.rmSync(temporary, { recursive: true, force: true });
}
