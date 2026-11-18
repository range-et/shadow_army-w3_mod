// RTSW v164 UTF-8 menu table. Format reference: 0x7A2C9E5D/Witcher3StringEditor.
// Provisional local IDs: reserve an ID space before public distribution.
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..');
const magic = 0x79321793;
const u16 = v => { const b = Buffer.alloc(2); b.writeUInt16LE(v); return b; };
const u32 = v => { const b = Buffer.alloc(4); b.writeUInt32LE(v >>> 0); return b; };
function hash(s) { let h = 0; for (const ch of s.toLowerCase()) h = (Math.imul(h, 31) + ch.charCodeAt(0)) >>> 0; return h; }
function count(v) {
  if (v <= 0 || v >= 4096) throw Error('Unsupported table size');
  return Buffer.from(v < 64 ? [v] : [(v & 63) | 64, v >> 6]);
}
function crypt(raw) {
  const b = Buffer.from(raw), n = b.length; let k = (magic >>> 8) & 65535;
  for (let i = 0; i < n; i++) {
    b[i] ^= ((n + 1) * k) & 255;
    k = ((k << 1) | (k >>> 15)) & 65535;
  }
  return b;
}
function decode(b) {
  if (b.toString('ascii', 0, 4) !== 'RTSW' || b.readUInt32LE(4) !== 164) throw Error('Invalid header');
  let p = 10;
  function readCount() {
    let n = 0, shift = 0;
    for (let i = 1; i <= 5; i++) {
      const x = b[p++]; n |= (x & (x > 127 ? 127 : i === 1 ? 63 : 255)) << shift;
      shift += x > 127 ? 7 : 6;
      if (x < 64 || (i >= 3 && x < 128)) return n;
    }
    throw Error('Invalid count');
  }
  const blocks = [], keys = [];
  for (let n = readCount(); n--; p += 12) blocks.push([b.readUInt32LE(p), b.readUInt32LE(p + 4), b.readUInt32LE(p + 8)]);
  for (let n = readCount(); n--; p += 8) keys.push([b.readUInt32LE(p), b.readUInt32LE(p + 4)]);
  const size = readCount(), base = p;
  if (base + size + 2 !== b.length) throw Error('Invalid buffer length: base=' + base + ' units=' + size + ' length=' + b.length);
  const strings = new Map(blocks.map(([id, offset, length]) => [id, crypt(b.subarray(base + offset, base + offset + length)).toString('utf8')]));
  return new Map(keys.map(([h, id]) => [h, strings.get(id)]));
}
const refDir = fs.readdirSync(path.join(root, 'references')).find(x => x.startsWith('Trophy Necromancy'));
const reference = decode(fs.readFileSync(path.join(root, 'references', refDir, 'mods/modtrophynecromancy/content/en.w3strings')));
if (reference.get(hash('panel_TrophyNecromancy')) !== 'Trophy Necromancy') throw Error('Reference verification failed');
const xmlPath = path.join(root, 'bin/config/r4game/user_config_matrix/pc/modShadowMonarch.xml');
const content = path.join(root, 'mods/modShadowMonarch/content');
const csvPath = path.join(content, 'csv/en.w3strings.csv');
let xml = fs.readFileSync(xmlPath, 'utf8');
let rows;
if (fs.existsSync(csvPath)) {
  rows = fs.readFileSync(csvPath, 'utf8').split(/\r?\n/).filter(x => x && !x.startsWith(';')).map(line => {
    const [id, , key, text] = line.split('|'); return { id: Number(id), key, text };
  });
} else {
  const entries = new Map([
    ['panel_ShadowMonarch', 'Shadow Monarch'], ['panel_ShadowMonarchArmy', 'Army Settings'],
    ['preset_Mods_miscellaneous_ShadowMonarch_ShadowMonarchArmy', 'Army Settings'], ['preset_SM_Default', 'Default']
  ]);
  xml = xml.replace(/(<Group[^>]*displayName=")[^"]+/, '$1Mods.miscellaneous.ShadowMonarch.ShadowMonarchArmy')
    .replace('displayName="Default"', 'displayName="SM_Default"')
    .replace(/<Var id="([^"]+)" displayName="([^"]+)"/g, (_, id, label) => {
      entries.set('option_SM_' + id, label); return `<Var id="${id}" displayName="SM_${id}"`;
    }).replace(/<Option id="([^"]+)" displayName="([^"]+)"/g, (_, id, label) => {
      entries.set('option_SM_' + label, label); entries.set('SM_' + label, label);
      return `<Option id="${id}" displayName="SM_${label}"`;
    }).replace(/ tags="[^"]*"/g, '');
  rows = [...entries].map(([key, text], i) => ({ id: 2146700000 + i, key, text }));
  fs.writeFileSync(xmlPath, xml);
  fs.mkdirSync(path.dirname(csvPath), { recursive: true });
  fs.writeFileSync(csvPath, ';meta[language=en]\n;id|key(hex)|key(str)|text\n' + rows.map(r => `${r.id}||${r.key}|${r.text}\n`).join(''));
}
// The game composes option and preset values using this prefix.
for (const r of [...rows]) {
  if (r.key.startsWith('SM_')) {
    const key = 'preset_value_' + r.key;
    if (!rows.some(x => x.key === key)) rows.push({ id: 2146700000 + rows.length, key, text: r.text });
  }
}
for (const [key, text] of [['preset_value_SM_Default', 'Default'], ['preset_value_', 'Custom']]) {
  if (!rows.some(x => x.key === key)) rows.push({ id: 2146700000 + rows.length, key, text });
}
fs.writeFileSync(csvPath, ';meta[language=en]\n;meta[version=164]\n;id|key(hex)|key(str)|text\n' + rows.map(r => `${r.id}||${r.key}|${r.text}\n`).join(''));
let offset = 0;
const blocks = [], buffer = [];
for (const r of [...rows].sort((a, b) => ((a.id ^ magic) >>> 0) - ((b.id ^ magic) >>> 0))) {
  const raw = Buffer.from(r.text, 'utf8');
  blocks.push(u32(r.id ^ magic), u32(offset), u32(raw.length));
  buffer.push(crypt(raw), Buffer.from([0])); offset += raw.length + 1;
}
const keys = [...rows].sort((a, b) => hash(a.key) - hash(b.key)).flatMap(r => [u32(hash(r.key)), u32(r.id ^ magic)]);
const data = Buffer.concat([Buffer.from('RTSW'), u32(164), u16(0x4397), count(rows.length), ...blocks, count(rows.length), ...keys, count(offset), ...buffer, u16(0x5139)]);
const result = decode(data);
for (const r of rows) if (result.get(hash(r.key)) !== r.text) throw Error('Round-trip failed: ' + r.key);
fs.writeFileSync(path.join(content, 'en.w3strings'), data);
console.log(`Verified reference format and ${rows.length} generated menu strings (${data.length} bytes).`);
