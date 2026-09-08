#!/usr/bin/env bash
# Zig grammar, definitions, local/qualified calls, test attribution, and deterministic cache round trips.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="${RIPWIRE_BIN:-$ROOT/build/ripwire}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir "$TMP/cache"
export XDG_CACHE_HOME="$TMP/cache"
cp -R "$ROOT/test/zigfix" "$TMP/fix"

"$BIN" "$TMP/fix" --no-cache > "$TMP/map.xml"
python3 - "$TMP/map.xml" <<'PY'
import sys, xml.etree.ElementTree as ET
tree = ET.parse(sys.argv[1])
rows = list(tree.iter('s'))
syms = {s.get('n'): s for s in rows}
expected = {'Point', 'Color', 'Value', 'add', 'increment', 'calculate', 'announce', 'add_test', 'test addition'}
assert set(syms) == expected, (set(syms), expected)
for name in {'Point', 'Color', 'Value'}:
    assert syms[name].get('t') == 'struct', (name, syms[name].attrib)
for name in expected - {'Point', 'Color', 'Value'}:
    assert syms[name].get('t') == 'fn', (name, syms[name].attrib)
def calls(name): return {c.get('n') for c in syms[name].iter('c')}
assert calls('increment') == {'add'}
assert calls('calculate') == {'increment', 'add'}
assert calls('add_test') == {'add'}
assert calls('test addition') == {'add'}
test_files = [f for f in tree.iter('f') if any(s.get('n') == 'add_test' for s in f.iter('s'))]
assert len(test_files) == 1 and 'test' in test_files[0].get('p', ''), [f.attrib for f in test_files]
print('  PASS Zig definitions, calls, and test-file attribution')
PY

"$BIN" "$TMP/fix" --no-cache --uses=print --legend=compact > "$TMP/uses-print.xml"
python3 - "$TMP/uses-print.xml" <<'PY'
import sys, xml.etree.ElementTree as ET
root = ET.parse(sys.argv[1]).getroot()
rows = list(root.iter('u'))
assert root.get('external') == '1', root.attrib
assert any(row.get('role') == 'call' and row.get('in_id') == 'announce' for row in rows), rows
print('  PASS qualified external call')
PY

"$BIN" "$TMP/fix" --deps --no-cache --legend=compact > "$TMP/deps.xml"
"$BIN" "$TMP/fix" --callees=add_test --no-cache --legend=compact > "$TMP/callees.xml"
python3 - "$TMP/deps.xml" "$TMP/callees.xml" <<'PY'
import sys, xml.etree.ElementTree as ET
deps = ET.parse(sys.argv[1]).getroot()
files = {row.get('p'): row for row in deps.iter('f')}
assert files['math.zig'].get('afferent') == '1', files['math.zig'].attrib
assert any(row.get('t') == 'math.zig' for row in files['math_test.zig'].iter('inc'))
calls = ET.parse(sys.argv[2]).getroot()
rows = list(calls.iter('s'))
assert calls.get('graph_ambiguous') == '0', calls.attrib
assert len(rows) == 1 and rows[0].get('p', '').startswith('math.zig:'), [r.attrib for r in rows]
print('  PASS @import capture, exact path resolution, and duplicate-name narrowing')
PY

for n in a b c; do "$BIN" "$TMP/fix" > "$TMP/$n.xml"; done
cmp "$TMP/map.xml" "$TMP/a.xml"
cmp "$TMP/a.xml" "$TMP/b.xml"
cmp "$TMP/b.xml" "$TMP/c.xml"
xmllint --noout "$TMP/c.xml"
echo '  PASS cold/warm determinism and XML'

python3 - "$TMP/fix/math.zig" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1]); s = p.read_text()
assert 'add(value, 1)' in s
p.write_text(s.replace('add(value, 1)', 'missing_add(value, 1)'))
PY
"$BIN" "$TMP/fix" --no-cache > "$TMP/mut.xml"
python3 - "$TMP/mut.xml" <<'PY'
import sys, xml.etree.ElementTree as ET
syms = {s.get('n'): s for s in ET.parse(sys.argv[1]).iter('s')}
assert 'add' not in {c.get('n') for c in syms['increment'].iter('c')}
print('  PASS call-site mutation removes the edge')
PY
