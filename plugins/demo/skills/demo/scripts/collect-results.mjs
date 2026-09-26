#!/usr/bin/env node
// Usage: node collect-results.mjs <run-dir>
// Reads <run-dir>/report.json (Playwright JSON reporter), copies videos and screenshots
// into <run-dir>/media/, and writes <run-dir>/manifest.json:
// { tests: [{ ac, title, file, status, durationMs, error, video, screenshots: [{ label, file }] }] }
import { readFileSync, writeFileSync, mkdirSync, copyFileSync, existsSync } from 'node:fs';
import { join, extname } from 'node:path';
import { execFileSync } from 'node:child_process';

const runDir = process.argv[2];
if (!runDir) {
  console.error('usage: collect-results.mjs <run-dir>');
  process.exit(1);
}
const report = JSON.parse(readFileSync(join(runDir, 'report.json'), 'utf8'));
const mediaDir = join(runDir, 'media');
mkdirSync(mediaDir, { recursive: true });

const hasFfmpeg = (() => {
  try { execFileSync('ffmpeg', ['-version'], { stdio: 'ignore' }); return true; } catch { return false; }
})();

const slug = (s) => s.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 60);

function* specs(suite, file) {
  for (const spec of suite.specs ?? []) yield { spec, file: suite.file ?? file };
  for (const child of suite.suites ?? []) yield* specs(child, suite.file ?? file);
}

function saveVideo(src, base) {
  if (hasFfmpeg) {
    const out = join(mediaDir, `${base}.mp4`);
    try {
      execFileSync('ffmpeg', ['-y', '-loglevel', 'error', '-i', src, '-c:v', 'libx264', '-pix_fmt', 'yuv420p',
        '-crf', '28', '-preset', 'veryfast', '-movflags', '+faststart', '-an', out]);
      return `media/${base}.mp4`;
    } catch { /* fall back to webm */ }
  }
  copyFileSync(src, join(mediaDir, `${base}.webm`));
  return `media/${base}.webm`;
}

const tests = [];
for (const top of report.suites ?? []) {
  for (const { spec, file } of specs(top)) {
    for (const t of spec.tests ?? []) {
      if (/^capture /.test(spec.title)) continue;
      const result = t.results?.at(-1) ?? {};
      const base = slug(spec.title);
      const ac = spec.title.match(/^(AC\d+[a-z]?)\b/i)?.[1]?.toUpperCase() ?? null;
      let video = null;
      const screenshots = [];
      let n = 0;
      for (const a of result.attachments ?? []) {
        if (a.name === 'video' && a.path && existsSync(a.path)) {
          video = saveVideo(a.path, base);
        } else if (a.contentType === 'image/png') {
          const name = `${base}-${String(++n).padStart(2, '0')}.png`;
          if (a.path && existsSync(a.path)) copyFileSync(a.path, join(mediaDir, name));
          else if (a.body) writeFileSync(join(mediaDir, name), Buffer.from(a.body, 'base64'));
          else continue;
          screenshots.push({ label: a.name === 'screenshot' ? 'Final state' : a.name, file: `media/${name}` });
        }
      }
      tests.push({
        ac,
        title: spec.title,
        file: `${file}:${spec.line}`,
        // t.status: expected | unexpected | flaky | skipped
        status: t.status === 'expected' ? 'passed' : t.status === 'skipped' ? 'skipped' : t.status === 'flaky' ? 'flaky' : 'failed',
        durationMs: result.duration ?? null,
        error: result.error?.message?.replace(/\u001b\[[0-9;]*m/g, '').split('\n').slice(0, 6).join('\n') ?? null,
        video,
        screenshots,
      });
    }
  }
}

writeFileSync(join(runDir, 'manifest.json'), JSON.stringify({ tests, videoFormat: hasFfmpeg ? 'mp4' : 'webm' }, null, 2));
const counts = tests.reduce((m, t) => ({ ...m, [t.status]: (m[t.status] ?? 0) + 1 }), {});
console.log(`${tests.length} tests`, counts, `→ ${join(runDir, 'manifest.json')}`);
