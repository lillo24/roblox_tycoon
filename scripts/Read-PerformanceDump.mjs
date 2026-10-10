// Offline reader for this task's Studio 742 Legacy HTML (R0FL) dumps.
// Executes the dump's embedded vendor decoder; use only trusted local captures.
// No downloads or third-party packages. Node 24.19.0 was used for PERF-02.
import fs from 'node:fs';
import zlib from 'node:zlib';
import vm from 'node:vm';
import path from 'node:path';

const [input, output] = process.argv.slice(2);
if (!input || !output || path.resolve(input) === path.resolve(output)) {
  throw new Error('Usage: node scripts/Read-PerformanceDump.mjs <legacy.html> <summary.json>');
}
const html = fs.readFileSync(input, 'utf8');
const comments = [...html.matchAll(/<!--([\s\S]*?)-->/g)].slice(0, 2).map(x => x[1]);
if (!comments[0]?.startsWith('R0FL') || !comments[1]) {
  throw new Error(`${input}: expected Studio Legacy HTML R0FL payload and embedded decoder`);
}
function inflate(value) {
  const compressed = Buffer.from(value, 'base64');
  if (compressed.length < 9) throw new Error(`${input}: truncated native payload`);
  const result = zlib.inflateSync(compressed.subarray(8), { maxOutputLength: 256 * 1024 * 1024 });
  if (result.length !== compressed.readUInt32LE(0)) throw new Error(`${input}: native payload length mismatch`);
  return result;
}
const raw = Buffer.concat([Buffer.from('    R0FL'), inflate(comments[0].slice(4))]);
const decoder = vm.createContext({ WebAssembly, TextDecoder, TextEncoder, console, setTimeout, clearTimeout });
// Offline execution boundary, not a security sandbox for arbitrary HTML.
vm.runInContext('self=globalThis;window=globalThis;document={currentScript:{src:""}};location={href:""};isWorker=false;output=[];ExecStatement=x=>output.push(x);SaveExportResult=()=>{};', decoder);
vm.runInContext(inflate(comments[1]).toString(), decoder, { timeout: 10000 });
decoder.Tools = await decoder.ToolsModule();
decoder.Tools.ccall('Init', 'number', []);
const ptr = decoder.Tools._malloc(raw.length);
decoder.Tools.HEAPU8.set(raw, ptr);
try {
  decoder.Tools.cwrap('ParseRaw', 'number', ['string', 'number', 'number'])(
    JSON.stringify({ fileName: path.basename(input), localId: 0, localGroupId: 0 }), ptr, raw.length);
} finally {
  decoder.Tools._free(ptr);
}
if (!decoder.output.length) throw new Error(`${input}: native decoder emitted no data`);

const fields = {
  MakeGroup: 'id name category numtimers isgpu total average max color',
  MakeTimer: 'id name group color colordark average max min exclaverage exclmax callaverage callcount total meta metaagg metamax',
  MakeFrame: 'id framestart frameend framestartgpu frameendgpu ts tt ti tl paused incomplete cpufreq usedmemorymb freememorymb allocmsecs allocs freemsecs frees cpu_waits_for_gpu jobs_walltime_ms render_walltime_ms gpu_time_ms',
};
const data = vm.createContext({ S: {} });
for (const [key, names] of Object.entries(fields)) {
  data[key] = (...args) => Object.fromEntries(names.split(' ').map((name, i) => [name, args[i]]));
}
data.MakeCounter = (...args) => args;
data.MakeTimes = (scale, ts) => ts.map(x => x * scale);
data.MakeTimesType = (scale, tt, ts) => ts.map((x, i) => tt[i] <= 127 ? x * scale : x);
data.MakeTimesExtra = (scale, extra, tt, ts) => ts.map((x, i) => x * (tt[i] === 4 ? extra : scale));
vm.runInContext(decoder.output.join('\n'), data, { timeout: 10000 });
if (!data.Frames?.length || data.Frames.some(f => f.incomplete)) {
  throw new Error(`${input}: expected nonempty complete frames; incomplete capture cannot use this summary`);
}
const spans = [], stacks = data.ThreadNames.map(() => []);
for (let f = 0; f < data.Frames.length; f++) {
  const frame = data.Frames[f];
  for (let t = 0; t < frame.ts.length; t++) {
    for (let k = 0; k < frame.ts[t].length; k++) {
      const type = frame.tt[t][k], id = frame.ti[t][k], time = frame.ts[t][k];
      if (type === 1) stacks[t].push({ id, start: time, frame: f });
      else if (type === 0 && stacks[t].length) {
        const open = stacks[t].pop();
        if (open.id !== id) throw new Error(`${input}: unmatched scope on thread ${t}, frame ${f}`);
        spans.push({ ...open, end: time, ms: time - open.start, thread: data.ThreadNames[t],
          threadIndex: t, name: data.TimerInfo[id]?.name });
      }
    }
  }
}
// Scopes are inclusive elapsed intervals, not CPU accounting. Overlap/nesting
// must not be summed as independent CPU; incomplete edge scopes are excluded.
const timers = new Map();
for (const s of spans.filter(x => x.threadIndex !== 0)) {
  if (!timers.has(s.id)) timers.set(s.id, { id: s.id, name: s.name, count: 0, totalMs: 0, maxMs: 0 });
  const t = timers.get(s.id);
  t.count++; t.totalMs += s.ms; t.maxMs = Math.max(t.maxMs, s.ms);
}
const frames = data.Frames.map((f, index) => ({ index, startMs: f.framestart, endMs: f.frameend,
  intervalMs: f.frameend - f.framestart, gpuMs: f.gpu_time_ms,
  usedMemoryMB: f.usedmemorymb, freeMemoryMB: f.freememorymb }));
if (frames.some(f => !Number.isFinite(f.intervalMs) || f.intervalMs <= 0)) {
  throw new Error(`${input}: invalid frame span`);
}
const worst = [...frames].sort((a, b) => b.intervalMs - a.intervalMs)[0];
const ranked = [...timers.values()].sort((a, b) => b.totalMs - a.totalMs);
const result = {
  input: path.basename(input), exportUtc: data.DumpUtcCaptureTime,
  platform: JSON.parse(data.PlatformInfo), frameCount: frames.length,
  spanMs: frames.at(-1).endMs - frames[0].startMs,
  above50: frames.filter(f => f.intervalMs > 50).length, worst, frames,
  topElapsedScopes: ranked.slice(0, 20),
  labels: ranked.filter(t => /PERF02|Garbage|GC/.test(t.name)),
  worstOverlap: spans.filter(s => s.threadIndex !== 0 && s.start < worst.endMs && s.end > worst.startMs)
    .map(s => ({ ...s, overlapMs: Math.min(s.end, worst.endMs) - Math.max(s.start, worst.startMs) }))
    .sort((a, b) => b.overlapMs - a.overlapMs).slice(0, 20),
  fixtureEvents: spans.filter(s => /PERF02 editor|PERF02 slow/.test(s.name)),
};
fs.writeFileSync(output, JSON.stringify(result, null, 2) + '\n');
console.log(JSON.stringify({ input: result.input, frames: frames.length, spanMs: result.spanMs,
  worstMs: worst.intervalMs, above50: result.above50 }));
