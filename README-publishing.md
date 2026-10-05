# How to publish updates to the Study Notes site

Live site: <https://theoscholar.github.io/studynotes/> *(after the one-time Pages setup below)*
Repository: <https://github.com/theoscholar/studynotes>

This folder **is** the Git working copy. Edit the originals in
`..\Study Notes\`, then run the publish script — it copies them in under their
clean published names, commits, and pushes.

Currently published: **9 character studies**. The Botswana and South Africa reports moved to the `africa` repository (Personal Study Projects\Countries\Countries Site) on Oct 05, 2026.
The Jeremiah guides in `..\Study Notes Site\` are deliberately *not* part of this
site; see "Adding the Jeremiah guides later" below.

---

## At a glance: what runs how often

| How often | What to run | Status |
| --- | --- | --- |
| **Per machine** (once) | Install Git for Windows; `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`; approve the GitHub browser sign-in | Already done on NUC-14 |
| **Per repository** (once) | `git init`, remote, commit identity, `.gitattributes` — **plus enable GitHub Pages in the browser** | Git side done; **Pages still needs enabling** |
| **Per update** | `.\publish.ps1` | The only recurring command |
| **Per new note** | Add a line to `name-map.tsv`, add a card in `index.html`, then `.\publish.ps1` | — |

---

## First publish

```powershell
cd "C:\Users\ThomS\OneDrive\Theo Library\studynotes-site"
.\publish.ps1 -WhatIf     # preview
.\publish.ps1             # commit and push
```

**Then enable GitHub Pages — this only works after the first push**, because a
repository with no commits has no branch to serve from:

1. Go to <https://github.com/theoscholar/studynotes/settings/pages>
2. **Build and deployment → Source:** *Deploy from a branch*
3. **Branch:** `main`, folder `/ (root)` → **Save**

The site appears at <https://theoscholar.github.io/studynotes/> within a minute
or two. This step is needed once, ever.

---

## Publishing an update

```powershell
cd "C:\Users\ThomS\OneDrive\Theo Library\studynotes-site"
.\publish.ps1
```

Variations:

```powershell
.\publish.ps1 -WhatIf                       # preview only, pushes nothing
.\publish.ps1 -Message "Revise Botswana"    # custom commit message
```

---

## Adding a new study note

1. Save the new file into `..\Study Notes\` (the top level, not a subfolder).
2. Add one line to `name-map.tsv`, **tab-separated**:

   ```
   Characters - Esther - A Queen Who Acted.html	character-esther.html
   ```

3. Add a card in `index.html`, copying an existing `<a class="card">` block.
4. Run `.\publish.ps1`.

If a file in `Study Notes` has no map entry, the script warns and skips it
rather than publishing something under a messy filename.

### Adding the Jeremiah guides later

The 7 Jeremiah pages live in `..\Study Notes Site\`. To fold them in: copy them
into this folder, add matching cards to `index.html`, and confirm each carries
the noindex tag (6 of the 7 currently do not). They have no counterpart in
`..\Study Notes\`, so they need no `name-map.tsv` entries — the script only
copies mapped files and leaves everything else alone.

---

## Search engine visibility

Every page carries `<meta name="robots" content="noindex, nofollow">`, matching
the Pioneer School site. `publish.ps1` checks this on every run and warns loudly
if a page is missing it. Keep the tag in any new page.

---

## Troubleshooting

**`Unable to create '.git/index.lock': File exists`.** A stale lock.
`publish.ps1` clears these automatically when no git process is running. By hand:

```powershell
Remove-Item ".git\index.lock", ".git\HEAD.lock", ".git\objects\maintenance.lock" -Force -ErrorAction SilentlyContinue
Get-ChildItem ".git\objects" -Recurse -Filter "tmp_obj_*" | Remove-Item -Force
```

**`git push` rejected — email privacy.** The commit used the wrong address:

```powershell
git config user.email "theoscholar@users.noreply.github.com"
git commit --amend --reset-author --no-edit
git push -u origin main
```

**Every file suddenly shows as modified.** Line endings. `.gitattributes` sets
`* -text` to prevent this; confirm it still exists, then `git config core.autocrlf false`.

**404 at the site URL.** Pages is not enabled yet, or the first deployment is
still running. Check the **Actions** tab on the repo.

**The site looks stale.** Pages caches hard — force-refresh with `Ctrl+F5`.

**OneDrive conflict files inside `.git`.** Delete the conflict copy. If the
repository is damaged beyond that, nothing is lost — the content is safe on
GitHub and in `..\Study Notes\`. Re-clone into a fresh folder.
