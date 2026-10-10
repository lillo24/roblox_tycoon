// Pair raw five-second host counters with a single completed probe window.
import fs from 'node:fs';
import path from 'node:path';
const [probePath, hostPath, output] = process.argv.slice(2);
if (!probePath || !hostPath || !output || [probePath, hostPath].some(p => path.resolve(p) === path.resolve(output))) {
  throw new Error('Usage: node scripts/Summarize-PerformanceHost.mjs <probe.jsonl> <host.jsonl> <summary.json>');
}
const read = file => fs.readFileSync(file, 'utf8').trim().split(/\r?\n/).map(JSON.parse);
const rows = read(probePath), host = read(hostPath);
const phases = rows.filter(x => x.side === 'server' && x.kind === 'phase');
const complete = rows.filter(x => x.kind === 'complete' && x.side === 'server');
if (complete.length !== 1 || !phases.length || host.length < 2) {
  throw new Error('Expected one completed probe window and at least two host samples');
}
const intervals = [];
for (let i = 1; i < host.length; i++) {
  const a = host[i - 1], b = host[i], dt = b.utc - a.utc;
  if (!(dt > 0)) throw new Error(`${hostPath}: non-increasing UTC at row ${i + 1}`);
  // Exclude cross-phase/boundary intervals rather than attribute mixed work.
  const phase = phases.find((p, k) => a.utc >= p.time && b.utc <= (phases[k + 1]?.time ?? complete[0].time))?.phase;
  if (!phase) continue;
  const cpu = b.cpuRaw.map(x => {
    const p = a.cpuRaw.find(y => y.core === x.core);
    if (!p || !(x.time100ns > p.time100ns)) throw new Error(`CPU counter discontinuity: ${x.core}`);
    return { core: x.core, percent: 100 * (1 - (x.idle100ns - p.idle100ns) / (x.time100ns - p.time100ns)) };
  });
  const memorySeconds = (b.memoryRaw.time - a.memoryRaw.time) / b.memoryRaw.frequency;
  if (!(memorySeconds > 0)) throw new Error('Memory counter timestamp discontinuity');
  const gpu = b.gpu3dRaw.flatMap(x => {
    const p = a.gpu3dRaw.find(y => y.engine === x.engine);
    return p && x.time100ns > p.time100ns
      ? [{ engine: x.engine, percent: 100 * (x.busy100ns - p.busy100ns) / (x.time100ns - p.time100ns) }] : [];
  });
  if (!gpu.length || !b.processes.length) throw new Error('Missing GPU/Studio observations');
  const studioCores = b.processes.reduce((n, x) => {
    const p = a.processes.find(y => y.pid === x.pid);
    return n + (p ? (x.cpuSeconds - p.cpuSeconds) / dt : 0);
  }, 0);
  intervals.push({ phase, from: a.utc, to: b.utc, cpu, gpu, studioCores,
    newPids: b.processes.filter(x => !a.processes.some(y => y.pid === x.pid)).map(x => x.pid),
    endedPids: a.processes.filter(x => !b.processes.some(y => y.pid === x.pid)).map(x => x.pid),
    availableMB: b.memoryRaw.availableMB,
    pagesInputPerSecond: (b.memoryRaw.pagesInput - a.memoryRaw.pagesInput) / memorySeconds,
    pageReadsPerSecond: (b.memoryRaw.pageReads - a.memoryRaw.pageReads) / memorySeconds,
    collectionMs: b.collectionMs, collectorCores: (b.collectorCpuSeconds - a.collectorCpuSeconds) / dt });
}
function stats(values) {
  if (!values.length || values.some(x => !Number.isFinite(x))) throw new Error('Missing/invalid phase observations');
  return { min: Math.min(...values), mean: values.reduce((a, b) => a + b, 0) / values.length, max: Math.max(...values) };
}
const summaries = phases.map(p => {
  const sample = intervals.filter(x => x.phase === p.phase);
  return { phase: p.phase, intervals: sample.length,
    totalCPU: stats(sample.map(x => x.cpu.find(c => c.core === '_Total').percent)),
    maxCore: stats(sample.map(x => Math.max(...x.cpu.filter(c => c.core !== '_Total').map(c => c.percent)))),
    studioCores: stats(sample.map(x => x.studioCores)), availableMB: stats(sample.map(x => x.availableMB)),
    pagesInput: stats(sample.map(x => x.pagesInputPerSecond)), pageReads: stats(sample.map(x => x.pageReadsPerSecond)),
    maxGpuEngine: stats(sample.map(x => Math.max(...x.gpu.map(g => g.percent)))),
    collectionMs: stats(sample.map(x => x.collectionMs)), collectorCores: stats(sample.map(x => x.collectorCores)) };
});
fs.writeFileSync(output, JSON.stringify({ rawSamples: host.length, summaries, intervals }, null, 2) + '\n');
console.log(JSON.stringify(summaries));
