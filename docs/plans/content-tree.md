# Content tree migration plan

Study content moves from flat marker text (`Content/parts/*.txt`) to an explicit tree: **Markdown as the editing source, JSON as the shipped format**. The old markers `(1)`, `1)`, `a)`, `◎`, `-`, `⇒` are *display* symbols — the new data stores meaning, and the app renderer maps meaning to symbols.

Exam date: **2026-10-31**. Until then the app must look the same; only deliberate structure fixes may change what students see.

## 1. Node model (data)

| Node | Fields | Replaces |
|---|---|---|
| `section` | `title`, `summary?`, `children` — depth = nesting | `(1)`, `1)`, heading-like `a)` |
| `term` | `label`, `text?`, `children?` | `◎ 라벨 : 설명` |
| `list` | `ordered: true`, `items[] {text, children?}` | `a) b) c)`, inline `a) … ⇒ b) …` |
| `item` | `text`, `role?` (`then`), `children?` | `-`, `⇒` (`role: then`) |
| `note` | `kind` (`mnemonic` \| `tip` \| `formula`), `text` | `(※ 암기법 …)`, `*` |
| `table` | `header[]`, `rows[][]` | region / rate lines squeezed into `⇒` |

Later (not in scope now): `law` reference per node (`"주택임대차보호법 8"`) for `law_diff`, stable node `id` for per-line favorites / "changed" badges.

JSON file: `parts/<id>.json` → `{"part": <id>, "nodes": [ … ]}`.

## 2. Markdown syntax (editing source)

```markdown
## 공동소유                     ← section depth 1
### 공유                        ← section depth 2 (#### = depth 3)
물건이 지분에 의하여 …          ← section summary (paragraph right under a heading)
- **법적성질**: 1개의 소유권이 … ← term (label + text)
- **공유관계성립**              ← term with children
  1. 법률행위에 의한 성립        ← ordered list item
     - 부동산인 때는 등기        ← item
- 공유물 관리는 지분의 과반수로 결정
  - → 보존행위는 단독으로 가능   ← item, role then
> 암기법: 전, 답, 과, 목 …      ← note (mnemonic); `> 참고:` tip, `> 공식:` formula
| 지역 | 보증금 | 최우선변제 |    ← table
```

Rules the compiler enforces (build fails otherwise):
- No skipped heading level; no heading inside a list.
- 2-space indentation, one node per line.
- `<!-- TODO: … -->` comments are allowed only while a part is being migrated; packaging fails if any remain in a migrated part.

## 3. Display mapping (renderer)

| Node | Phase A (now → exam) | Phase B (after exam) |
|---|---|---|
| section depth 1 / 2 | `(1)` / `1)` | `(1)` / `1)` |
| section depth 3, ordered list | `a)` | `①②③` |
| term | `◎ 라벨 : 설명` | `◎` + **bold label** |
| item | `-` | `•` |
| item `then` | `⇒` | `⇒` |
| note mnemonic / tip / formula | `(※ 암기법 : …)` / `*` | `※ 암기:` tinted / `※` / monospace |
| table | text lines | real table |
| depth | leading spaces | paragraph indent |

Phase A output must equal today's `LSDocumentRecognizer.toString` output for every unfixed part (byte-for-byte), which proves the migration changed nothing visible.

## 4. Phases

### P1 — Tooling (Scripts)
- `Scripts/content_md.py` (merged): exact port of the app parser, old-format md, `check`, `lint`.
- New `migrate <id>`: old tree → new Markdown (§2). Deterministic mapping; every ambiguous spot from `lint` gets a `<!-- TODO -->`.
- New `build <id>|all`: new Markdown → `parts/<id>.json`, with the §2 checks.
- New `render-a <id>`: JSON → Phase A text; `parity <id>` compares it with the current app render.
- Pilot: the 10 clean parts (14 21 28 39 40 43 44 56 57 58) + parts 1 and 24.

### P2 — App (Phase A renderer)
- `ContentNode` Codable model; `ContentLoader` reads `parts/<id>.json`, falls back to `parts/<id>.txt` per part (mixed state allowed during migration).
- Phase A renderer → same text / attributes as today (SwiftUITextView, search highlight, scroll restore unchanged).
- Quiz: build questions from the JSON tree (adapter to the existing `RNQuestionInfo` inputs first).
- Keep `LSDocumentRecognizer` only for the `.txt` fallback; remove when all parts are JSON.

### P3 — Part-by-part migration
- For each part: `migrate` → resolve TODOs (fix misparses) → `build` → `parity` (differences only where a fix was intended) → `content-reviewer` → package.
- Order: clean parts first, then by lint load (heaviest last: 10, 7, 9, 6, 68, 13).
- Content version bump per batch; each batch is its own PR.

### P4 — After the exam
- Phase B symbols in the renderer (optionally a "기본 / 새 스타일" setting).
- Tables for figure-heavy parts, `law` references, stable node ids.
- Remove `.txt` + `LSDocumentRecognizer`.

## 5. Storage & privacy
- Content text stays private (public repo). `ContentSource/` (Markdown) is gitignored like `Content/`.
- Markdown becomes the source of truth, so it must be backed up: add it to the encrypted archive (git-secret), e.g. `ContentSource.zip.secret`, packaged alongside `Content.zip.secret`.
- `Content.zip` ships `parts/<id>.json` (and `.txt` until P4).

## 6. Skills / agents to update
- `law-content-update`: edit Markdown, then `build` + `parity`; packaging runs `build all`.
- `law-summary-review`: diff Markdown instead of txt.
- `content-editor` / `content-reviewer` agent docs: mention the node syntax.

## 7. Known parser bugs (fixed by the switch)
- Crash when `◎` has no numbered heading above it (`indexingParent` force unwrap).
- Crash on the 26th `a)` (`lowerAlpha`).
- `가)` parsed as untyped; `N.` would split decimals like `1.5`; `fullRange` uses character count instead of UTF-16 length.
