# How to publish updates to the Bible Characters site

Live site: <https://theoscholar.github.io/biblecharacters/> *(after the one-time Pages setup below)*
Repository: <https://github.com/theoscholar/biblecharacters>

This folder **is** the Git working copy. Edit or add the guides in the parent
folder (`..\Character Study Notes\`), then run the publish script — it copies them in
under their clean published names, commits, and pushes.

Currently published: **9 character studies** — Enoch, Noah, Abraham (2), Sarah, Rebekah, Jacob, Joseph, and Daniel with his companions. Moved here from the `studynotes` repository on Oct 05, 2026 (history kept); the old repository is the `studynotes` remote in this folder.

---

## At a glance

| How often | What to run | Status |
| --- | --- | --- |
| **Per machine** (once) | Install Git for Windows; `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`; approve the GitHub browser sign-in | Already done on NUC-14 |
| **Per repository** (once) | `git init`, remote, commit identity, `.gitattributes` — **plus enable GitHub Pages in the browser** | Git side done; **first push and Pages still needed** |
| **Per update** | `.\publish.ps1` | The only recurring command |
| **Per new guide** | Add a line to `name-map.tsv`, add a card in `index.html`, then `.\publish.ps1` | — |

---

## First publish

```powershell
cd "C:\Users\ThomS\OneDrive\Theo Outputs\Study Notes\Character Study Notes\Character Study Notes Site"
git push -u origin main
```

(The first commit already exists locally, so a plain push is all the first
publish needs. Thereafter use `.\publish.ps1`.)

**Then enable GitHub Pages — this only works after the first push:**

1. Go to <https://github.com/theoscholar/biblecharacters/settings/pages>
2. **Build and deployment → Source:** *Deploy from a branch*
3. **Branch:** `main`, folder `/ (root)` → **Save**

The site appears at <https://theoscholar.github.io/biblecharacters/> within a
minute or two. This step is needed once, ever.

---

## Publishing an update

```powershell
cd "C:\Users\ThomS\OneDrive\Theo Outputs\Study Notes\Character Study Notes\Character Study Notes Site"
.\publish.ps1
```

Variations:

```powershell
.\publish.ps1 -WhatIf                             # preview only, pushes nothing
.\publish.ps1 -Message "Add Saul"       # custom commit message
```

---

## Adding a new character study

1. Save the study into `..\Character Study Notes\` (the parent folder).
2. Add one line to `name-map.tsv`, **tab-separated**:

   ```
   Characters - Saul - The King Who Would Not Be Corrected.html	character-saul.html
   ```

3. Add a card in `index.html`, copying an existing `<a class="card">` block.
4. Run `.\publish.ps1`.

If a study has no map entry, the script warns and skips it rather than
is deliberately unmapped.

---

## Search engine visibility

Every page should carry `<meta name="robots" content="noindex, nofollow">`.
`publish.ps1` checks this on every run and warns if a page is missing it.

---

## Troubleshooting

**`Unable to create '.git/index.lock': File exists`.** A stale lock.
`publish.ps1` clears these automatically when no git process is running. By hand:

```powershell
Remove-Item ".git\index.lock", ".git\HEAD.lock" -Force -ErrorAction SilentlyContinue
Get-ChildItem ".git\objects" -Recurse -Filter "tmp_obj_*" | Remove-Item -Force
```

**`git push` rejected — email privacy.**

```powershell
git config user.email "theoscholar@users.noreply.github.com"
git commit --amend --reset-author --no-edit
git push -u origin main
```

**`git push` rejected — remote has commits (e.g. a README created on GitHub).**

```powershell
git pull --rebase origin main
git push -u origin main
```

**Every file suddenly shows as modified.** Line endings. `.gitattributes` sets
`* -text`; confirm it still exists, then `git config core.autocrlf false`.

**404 at the site URL.** Pages is not enabled yet, or the first deployment is
still running. Check the **Actions** tab on the repo.

**The site looks stale.** Pages caches hard — force-refresh with `Ctrl+F5`.

**OneDrive conflict files inside `.git`.** Delete the conflict copy. If the
repository is damaged, nothing is lost — the content is safe on GitHub and in
`..\Character Study Notes\`. Re-clone into a fresh folder.
