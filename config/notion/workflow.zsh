# ─────────────────────────────────────────────────────────────────────────────
# Notion + neovim CLI workflow (uses the `ntn` Notion CLI)
#
# Files are named  <slug>.<page-id>.md  so the page id travels with the file.
# Sync state lives under $NOTION_DIR/.notion/state/<id>.json
#
# Commands:
#   nsearch              fuzzy-search all pages (shows parent breadcrumb), edit pick
#   ntree [id]           walk the page tree: descend children, `..` up, edit/open,
#                        «new page here» / ctrl-n to add a child under the node
#   nbrowse [ds|db-id]   fuzzy-pick from a database/data-source, open + push
#   nget <id> [path]     fetch a page to a local .md file (no edit)
#   nedit <id>           fetch -> nvim -> push back (with conflict check)
#   nnew [title]         create a new page under $NOTION_PARENT, edit, push
#   npush <file>         push a local file back to Notion (id from filename)
#   npull <file|id>      refresh a local file from Notion
#   nsync [folder]       two-way reconcile every tracked file in a folder
#   nreindex             drop the cached workspace index + parent labels
#
# Browse/search results are paginated (the whole workspace is walked, not just
# the first 100). nsearch/ntree/nbrowse fetch metadata only — never page bodies.
# The ntree index and parent-label lookups are cached on disk for
# $NOTION_CACHE_TTL seconds (default 300); run `nreindex` to refresh sooner.
# ─────────────────────────────────────────────────────────────────────────────

export NOTION_DIR="${NOTION_DIR:-$HOME/notion}"
# Default parent for `nnew`. Set to  page:<id>  data-source:<id>  or  database:<id>
# export NOTION_PARENT="data-source:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
# Default database for `nbrowse` with no argument:
# export NOTION_DB="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# ── internal helpers ─────────────────────────────────────────────────────────

_n_state_dir() { print -r -- "$NOTION_DIR/.notion/state"; }

# slugify a title -> safe filename stem
_n_slug() {
  print -r -- "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' \
    | cut -c1-60
}

# extract a page id (dashed uuid) from a filename, else empty
_n_id_from_file() {
  local b="${1:t}"
  print -r -- "$b" | grep -oE '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}' | tail -1
}

_n_sha() { shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'; }

# ── caching & pagination helpers ─────────────────────────────────────────────

# log to stderr when $NOTION_DEBUG is set (e.g. `NOTION_DEBUG=1 ntree`)
_n_log() { [[ -n "$NOTION_DEBUG" ]] && print -u2 -- "notion[$(date +%T)] $*"; }

# true if $1 exists and is younger than $NOTION_CACHE_TTL seconds (default 300)
_n_cache_fresh() {
  local f="$1" ttl="${NOTION_CACHE_TTL:-300}" now mtime
  [[ -f "$f" ]] || return 1
  now="$(date +%s)"
  mtime="$(stat -f %m "$f" 2>/dev/null)" || mtime="$(stat -c %Y "$f" 2>/dev/null)"
  [[ -n "$mtime" ]] || return 1
  (( now - mtime < ttl ))
}

# _n_search_all <json-body>  — page through /v1/search, emitting each raw
# response JSON to stdout (a stream jq consumes with `.results[]?`).
_n_search_all() {
  local body="$1" cursor="" prev_cursor="" page resp n=0 max="${NOTION_MAX_PAGES:-200}"
  while :; do
    if [[ -n "$cursor" ]]; then
      page="$(jq -n --argjson b "$body" --arg c "$cursor" '$b + {start_cursor:$c}')"
    else
      page="$body"
    fi
    (( n++ ))
    _n_log "search page $n (cursor=${cursor:0:8}${cursor:+…}) → calling ntn api v1/search"
    resp="$(ntn api v1/search -d "$page" 2>/dev/null)" || { _n_log "search page $n: ntn api FAILED"; break; }
    [[ -z "$resp" ]] && { _n_log "search page $n: empty response"; break; }
    _n_log "search page $n: $(jq -r '.results|length' <<<"$resp" 2>/dev/null) results, has_more=$(jq -r '.has_more' <<<"$resp" 2>/dev/null)"
    print -r -- "$resp"
    [[ "$(jq -r '.has_more' <<<"$resp" 2>/dev/null)" == "true" ]] || { _n_log "search done after $n page(s)"; break; }
    prev_cursor="$cursor"
    cursor="$(jq -r '.next_cursor // empty' <<<"$resp" 2>/dev/null)"
    [[ -z "$cursor" ]] && { _n_log "search: has_more but no next_cursor — stopping"; break; }
    [[ "$cursor" == "$prev_cursor" ]] && { _n_log "search: cursor did not advance — stopping to avoid loop"; break; }
    (( n >= max )) && { _n_log "search: hit NOTION_MAX_PAGES=$max — stopping"; break; }
  done
}

# _n_query_all <data-source-id>  — page through a data-source query, emitting
# each raw response JSON to stdout.
_n_query_all() {
  local ds="$1" cursor="" prev_cursor="" body resp n=0 max="${NOTION_MAX_PAGES:-200}"
  while :; do
    if [[ -n "$cursor" ]]; then
      body="$(jq -n --arg c "$cursor" '{page_size:100, start_cursor:$c}')"
    else
      body='{"page_size":100}'
    fi
    (( n++ ))
    _n_log "query page $n (cursor=${cursor:0:8}${cursor:+…}) → v1/data_sources/$ds/query"
    resp="$(ntn api "v1/data_sources/$ds/query" -d "$body" 2>/dev/null)" || { _n_log "query page $n: ntn api FAILED"; break; }
    [[ -z "$resp" ]] && { _n_log "query page $n: empty response"; break; }
    _n_log "query page $n: $(jq -r '.results|length' <<<"$resp" 2>/dev/null) results, has_more=$(jq -r '.has_more' <<<"$resp" 2>/dev/null)"
    print -r -- "$resp"
    [[ "$(jq -r '.has_more' <<<"$resp" 2>/dev/null)" == "true" ]] || { _n_log "query done after $n page(s)"; break; }
    prev_cursor="$cursor"
    cursor="$(jq -r '.next_cursor // empty' <<<"$resp" 2>/dev/null)"
    [[ -z "$cursor" ]] && { _n_log "query: has_more but no next_cursor — stopping"; break; }
    [[ "$cursor" == "$prev_cursor" ]] && { _n_log "query: cursor did not advance — stopping to avoid loop"; break; }
    (( n >= max )) && { _n_log "query: hit NOTION_MAX_PAGES=$max — stopping"; break; }
  done
}

# read a stream of /v1/search responses on stdin, emit one TSV row per
# page/database:  id \t title \t parent_type \t parent_id \t object
_n_index_emit() {
  jq -r '
    .results[]? | select(.object=="page" or .object=="database")
    | . as $r
    | (if $r.object=="database"
         then ([$r.title[]?.plain_text]|join(""))
         else ([$r.properties[]?|select(.type=="title")|.title[]?.plain_text]|join(""))
       end) as $t
    | [ $r.id,
        (if ($t|length)==0 then "(untitled)" else $t end),
        $r.parent.type,
        ($r.parent.page_id // $r.parent.database_id // $r.parent.data_source_id // ""),
        $r.object ] | @tsv'
}

# emit the cached workspace index TSV, rebuilding (paginated) if stale.
# Pass any argument to force a rebuild.
_n_index() {
  local cdir="$NOTION_DIR/.notion/cache"; mkdir -p "$cdir"
  local cf="$cdir/index.tsv"
  if [[ -z "$1" ]] && _n_cache_fresh "$cf"; then
    _n_log "index: using cached $cf ($(wc -l < "$cf" | tr -d ' ') rows)"
    cat "$cf"; return
  fi
  _n_log "index: rebuilding (paginated workspace search)…"
  _n_search_all '{"page_size":100}' | _n_index_emit > "$cf"
  _n_log "index: built $cf ($(wc -l < "$cf" | tr -d ' ') rows)"
  cat "$cf"
}

# fzf-pick a workspace-level (root) page from an index TSV on $1; echoes its id
_n_pick_root() {
  print -r -- "$1" \
    | awk -F'\t' '$3=="workspace" && $5=="page"{printf "%s\t%s\n",$2,$1}' \
    | fzf --with-nth=1 --delimiter='\t' --reverse --height=60% --prompt='root> ' \
    | sed 's/.*\t//'
}

# remote last_edited_time for a page id
_n_remote_edited() {
  ntn api "v1/pages/$1" 2>/dev/null | jq -r '.last_edited_time // empty'
}

# title for a page id (joins all title-type rich text)
_n_remote_title() {
  ntn api "v1/pages/$1" 2>/dev/null \
    | jq -r '[.properties[]? | select(.type=="title") | .title[]?.plain_text] | join("")' 2>/dev/null
}

# human label for a parent (type, id) — cached to disk under .notion/cache
_n_parent_label() {
  local type="$1" pid="$2"
  [[ -z "$pid" ]] && { print -r -- "workspace"; return; }
  local cdir="$NOTION_DIR/.notion/cache"; mkdir -p "$cdir"
  local cf="$cdir/$pid.label"
  if _n_cache_fresh "$cf"; then cat "$cf"; return; fi
  local label
  case "$type" in
    page_id)     label="$(_n_remote_title "$pid")" ;;
    database_id) label="🗂 $(ntn api "v1/databases/$pid" 2>/dev/null | jq -r '[.title[]?.plain_text]|join("")')" ;;
    *)           label="" ;;
  esac
  [[ -z "$label" || "$label" == "🗂 " ]] && label="(untitled)"
  print -r -- "$label" | tee "$cf"
}

# emit a tree menu for a page id from the workspace index ($2): "label\taction\ttarget"
# lines. Reads parent + children straight from the index — no block-body fetch.
_n_children_menu() {
  local id="$1" idx="$2"
  local ptype pid
  IFS=$'\t' read -r ptype pid < <(print -r -- "$idx" \
    | awk -F'\t' -v id="$id" '$1==id{print $3"\t"$4; exit}')
  printf '✏️  «edit this page»\tedit\t%s\n' "$id"
  printf '➕ «new page here»\tnew\t%s\n' "$id"
  case "$ptype" in
    page_id)   [[ -n "$pid" ]] && printf '⬆️  ..\tup\t%s\n' "$pid" ;;
    *)         printf '⬆️  .. (roots)\troot\t\n' ;;
  esac
  print -r -- "$idx" | awk -F'\t' -v id="$id" '
    $4==id {
      if ($5=="database") printf "🗂 %s\tdb\t%s\n",   $2, $1
      else                printf "📄 %s\tpage\t%s\n", $2, $1
    }'
}

# write sync state for an id given the local file
_n_save_state() {
  local id="$1" file="$2"
  local sd; sd="$(_n_state_dir)"; mkdir -p "$sd"
  local edited; edited="$(_n_remote_edited "$id")"
  local sha; sha="$(_n_sha "$file")"
  jq -n --arg e "$edited" --arg s "$sha" --arg f "${file:t}" \
    '{remote_last_edited:$e, local_sha:$s, file:$f}' > "$sd/$id.json"
}

_n_state_field() { jq -r ".$2 // empty" "$(_n_state_dir)/$1.json" 2>/dev/null; }

# fetch a page id to a destination file (creates dirs)
_n_fetch() {
  local id="$1" dest="$2"
  mkdir -p "${dest:h}"
  if ! ntn pages get "$id" > "$dest" 2>/tmp/ntn.err; then
    print -u2 "notion: failed to fetch $id"; cat /tmp/ntn.err >&2; return 1
  fi
}

# choose a destination filename in $NOTION_DIR for a page id
_n_dest_for() {
  local id="$1"
  # reuse existing tracked file if present
  local existing; existing=$(find "$NOTION_DIR" -type f -name "*$id.md" -not -path '*/.notion/*' 2>/dev/null | head -1)
  if [[ -n "$existing" ]]; then print -r -- "$existing"; return; fi
  local title; title="$(_n_remote_title "$id")"; [[ -z "$title" ]] && title="page"
  print -r -- "$NOTION_DIR/$(_n_slug "$title").$id.md"
}

# ── core commands ────────────────────────────────────────────────────────────

# nget <id> [dest]   — fetch only
nget() {
  local id="$1"; [[ -z "$id" ]] && { print -u2 "usage: nget <page-id> [dest]"; return 1; }
  local dest="${2:-$(_n_dest_for "$id")}"
  _n_fetch "$id" "$dest" || return 1
  _n_save_state "$id" "$dest"
  print -r -- "$dest"
}

# nedit <id>   — fetch, edit in $EDITOR, push back if changed (conflict-checked)
nedit() {
  local id="$1"; [[ -z "$id" ]] && { print -u2 "usage: nedit <page-id>"; return 1; }
  local dest; dest="$(_n_dest_for "$id")"
  local baseline_remote; baseline_remote="$(_n_remote_edited "$id")"
  _n_fetch "$id" "$dest" || return 1
  local orig="$NOTION_DIR/.notion/orig/$id.md"; mkdir -p "${orig:h}"; cp "$dest" "$orig"

  "${VISUAL:-${EDITOR:-nvim}}" "$dest"

  if cmp -s "$dest" "$orig"; then
    print "notion: no changes — nothing pushed."
    _n_save_state "$id" "$dest"; return 0
  fi

  local now_remote; now_remote="$(_n_remote_edited "$id")"
  if [[ -n "$baseline_remote" && "$now_remote" != "$baseline_remote" ]]; then
    print -u2 "⚠️  notion: page changed remotely since you opened it ($now_remote)."
    print -u2 "    Your edits are saved locally at: $dest"
    read "ans?    Overwrite the remote page anyway? [y/N] "
    [[ "$ans" == [yY]* ]] || { print "notion: push aborted."; return 1; }
  fi

  if ntn pages update "$id" < "$dest"; then
    print "notion: pushed → $id"
    _n_save_state "$id" "$dest"
  else
    print -u2 "notion: push failed (local copy kept at $dest)"; return 1
  fi
}

# npush <file>   — push an existing local file back (id parsed from filename)
npush() {
  local file="$1"; [[ -f "$file" ]] || { print -u2 "usage: npush <file.md>"; return 1; }
  local id; id="$(_n_id_from_file "$file")"
  [[ -z "$id" ]] && { print -u2 "notion: no page id in filename '$file' (expected <slug>.<uuid>.md)"; return 1; }
  if ntn pages update "$id" < "$file"; then
    print "notion: pushed → $id"; _n_save_state "$id" "$file"
  else
    print -u2 "notion: push failed"; return 1
  fi
}

# npull <file|id>   — refresh a local file from Notion
npull() {
  local arg="$1"; [[ -z "$arg" ]] && { print -u2 "usage: npull <file.md|page-id>"; return 1; }
  local id file
  if [[ -f "$arg" ]]; then file="$arg"; id="$(_n_id_from_file "$arg")"
  else id="$arg"; file="$(_n_dest_for "$id")"; fi
  [[ -z "$id" ]] && { print -u2 "notion: could not determine page id"; return 1; }
  _n_fetch "$id" "$file" || return 1
  _n_save_state "$id" "$file"
  print -r -- "$file"
}

# _n_new_under <page-id>   — prompt (on the tty) for a title and create a child
# page under that page. Prints status to stderr; echoes "<id>\t<title>" on success.
# Reads from /dev/tty so it works even when called inside $(...).
_n_new_under() {
  local parent_id="$1" title
  print -n "new page title: " > /dev/tty
  IFS= read -r title < /dev/tty
  [[ -z "${title//[[:space:]]/}" ]] && { print -u2 "notion: empty title — not created."; return 1; }
  local out; out="$(print -r -- "# $title" | ntn pages create --parent "page:$parent_id" 2>&1)" || {
    print -u2 "notion: create failed:"; print -u2 -- "$out"; return 1; }
  local id; id="$(print -r -- "$out" | grep -oE '[0-9a-fA-F-]{36}' | head -1)"
  [[ -z "$id" ]] && { print -u2 "notion: created but couldn't parse id:"; print -u2 -- "$out"; return 1; }
  print -u2 "notion: created “$title” → $id"
  nget "$id" >/dev/null 2>&1 && print -u2 "  synced locally"
  printf '%s\t%s\n' "$id" "$title"
}

# nnew [title]   — create a page under $NOTION_PARENT, edit it, then sync down
nnew() {
  [[ -z "$NOTION_PARENT" ]] && { print -u2 "notion: set NOTION_PARENT (e.g. data-source:<id> or page:<id>)"; return 1; }
  local title="$*"
  local tmp; tmp="$(mktemp /tmp/notion-new.XXXXXX.md)"
  if [[ -n "$title" ]]; then print -r -- "# $title" > "$tmp"; print >> "$tmp"; fi
  "${VISUAL:-${EDITOR:-nvim}}" "$tmp"
  [[ -s "$tmp" ]] || { print "notion: empty — not created."; rm -f "$tmp"; return 0; }
  local out; out="$(ntn pages create --parent "$NOTION_PARENT" < "$tmp" 2>&1)" || {
    print -u2 "notion: create failed:"; print -u2 -- "$out"; rm -f "$tmp"; return 1; }
  print -- "$out"
  local id; id="$(print -- "$out" | grep -oE '[0-9a-fA-F-]{36}' | head -1)"
  rm -f "$tmp"
  [[ -n "$id" ]] && { print "notion: created $id"; nget "$id" >/dev/null && print "  synced locally"; }
}

# ── fuzzy pickers ────────────────────────────────────────────────────────────

# emit "TITLE\tID" lines from a v1/search response on stdin
_n_pick_from_json() {
  jq -r '
    .results[]? | select(.object=="page")
    | ([.properties[]? | select(.type=="title") | .title[]?.plain_text] | join(""))
      as $t
    | ((if $t=="" then "(untitled)" else $t end) + "\t" + .id)'
}

# nsearch [query]   — fuzzy-search every page, showing each page's parent, edit the pick
nsearch() {
  local q="$*"
  local body; body="$(jq -n --arg q "$q" '{query:$q, page_size:100, filter:{property:"object", value:"page"}}')"
  # rows: id \t title \t ptype \t pid
  local rows
  rows="$(_n_search_all "$body" | jq -r '
    .results[]? | select(.object=="page")
    | ([.properties[]?|select(.type=="title")|.title[]?.plain_text]|join("")) as $t
    | [ .id, (if $t=="" then "(untitled)" else $t end), .parent.type,
        (.parent.page_id // .parent.database_id // .parent.data_source_id // "") ] | @tsv')"
  [[ -z "$rows" ]] && { print "notion: no results."; return 1; }
  # resolve each unique parent once
  typeset -A plabel; local ptype pid
  while IFS=$'\t' read -r ptype pid; do
    [[ -z "$pid" || -n "${plabel[$pid]}" ]] && continue
    plabel[$pid]="$(_n_parent_label "$ptype" "$pid")"
  done < <(print -r -- "$rows" | awk -F'\t' 'NF>=4{print $3"\t"$4}' | sort -u)
  local pick id title
  pick=$(print -r -- "$rows" | while IFS=$'\t' read -r id title ptype pid; do
            printf '%s\t%s  ·  %s\n' "$id" "$title" "${plabel[$pid]:-workspace}"
          done | fzf --with-nth=2.. --delimiter='\t' --height=60% --reverse --prompt='notion> ') || return
  id="${pick%%$'\t'*}"
  [[ -n "$id" ]] && nedit "$id"
}

# ntree [page-id]   — navigate the page tree; ↵ a child to descend, pick «edit» to open
ntree() {
  _n_log "ntree: loading workspace index…"
  local idx; idx="$(_n_index)"
  _n_log "ntree: index has $(print -r -- "$idx" | grep -c . ) row(s)"
  [[ -z "$idx" ]] && { print -u2 "notion: workspace index is empty (check access / run nreindex)"; return 1; }
  local id="$1"
  if [[ -z "$id" ]]; then
    id="$(_n_pick_root "$idx")"; [[ -z "$id" ]] && return
  fi
  while true; do
    local title; title="$(print -r -- "$idx" | awk -F'\t' -v id="$id" '$1==id{print $2; exit}')"
    [[ -z "$title" ]] && title="$(_n_remote_title "$id")"
    [[ -z "$title" ]] && title="(untitled)"
    local out key choice action target
    out=$(_n_children_menu "$id" "$idx" | fzf --with-nth=1 --delimiter='\t' --reverse --height=70% \
            --expect=ctrl-n --prompt="${title} ▸ " \
            --header='↵ descend · «edit» open · ➕ new page (or ctrl-n) · .. up') || return
    key="${out%%$'\n'*}"; choice="${out#*$'\n'}"
    if [[ "$key" == "ctrl-n" ]]; then
      action="new"; target="$id"
    else
      [[ -z "$choice" ]] && return
      action="${${choice#*$'\t'}%%$'\t'*}"; target="${choice##*$'\t'}"
    fi
    case "$action" in
      edit) nedit "$id"; return ;;
      up|page) id="$target" ;;
      root) id="$(_n_pick_root "$idx")"; [[ -z "$id" ]] && return ;;
      db)   nbrowse "$target"; return ;;
      new)
        local res; res="$(_n_new_under "$target")"
        if [[ -n "$res" ]]; then
          local nid="${res%%$'\t'*}" ntitle="${res#*$'\t'}"
          # show the new child immediately without a full workspace re-walk
          idx="${idx}"$'\n'"${nid}"$'\t'"${ntitle}"$'\t'"page_id"$'\t'"${target}"$'\t'"page"
          printf '%s\t%s\tpage_id\t%s\tpage\n' "$nid" "$ntitle" "$target" \
            >> "$NOTION_DIR/.notion/cache/index.tsv" 2>/dev/null
        fi
        ;;
      *)    return ;;
    esac
  done
}

# nbrowse [data-source-id | database-id]   — pick from a database, edit
nbrowse() {
  local ds="${1:-$NOTION_DB}"
  [[ -z "$ds" ]] && { print -u2 "usage: nbrowse <data-source-id|database-id>   (or set \$NOTION_DB)"; return 1; }
  # if given a database id, resolve to its first data source
  local resolved
  resolved=$(ntn datasources resolve "$ds" --json 2>/dev/null | jq -r '.[0].id // .data_sources[0].id // empty')
  [[ -n "$resolved" ]] && ds="$resolved"
  local pick
  pick=$(_n_query_all "$ds" | _n_pick_from_json \
    | fzf --with-nth=1 --delimiter='\t' --height=60% --reverse --prompt='db> ') || return
  local id; id="${pick##*$'\t'}"
  [[ -n "$id" ]] && nedit "$id"
}

# nreindex   — drop cached workspace index + parent labels (forces a fresh walk)
nreindex() {
  local cdir="$NOTION_DIR/.notion/cache"
  rm -f "$cdir/index.tsv" "$cdir"/*.label 2>/dev/null
  print "notion: cache cleared (index + parent labels)"
}

# ── two-way folder sync ──────────────────────────────────────────────────────

# nsync [folder]   — reconcile local <-> remote for every tracked file
nsync() {
  local dir="${1:-$NOTION_DIR}"
  local f id sd; sd="$(_n_state_dir)"
  local -i pushed=0 pulled=0 conflicts=0 skipped=0
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    id="$(_n_id_from_file "$f")"
    [[ -z "$id" ]] && { skipped+=1; continue; }

    local st_sha st_rem; st_sha="$(_n_state_field "$id" local_sha)"; st_rem="$(_n_state_field "$id" remote_last_edited)"
    local cur_sha cur_rem; cur_sha="$(_n_sha "$f")"; cur_rem="$(_n_remote_edited "$id")"
    local local_changed=0 remote_changed=0
    [[ "$cur_sha" != "$st_sha" ]] && local_changed=1
    [[ -n "$st_rem" && "$cur_rem" != "$st_rem" ]] && remote_changed=1

    if (( local_changed && remote_changed )); then
      print "‼️  conflict: ${f:t}  (changed both sides — skipped)"; conflicts+=1
    elif (( local_changed )); then
      if ntn pages update "$id" < "$f"; then print "⬆️  pushed  ${f:t}"; _n_save_state "$id" "$f"; pushed+=1
      else print -u2 "push failed: ${f:t}"; fi
    elif (( remote_changed )); then
      if _n_fetch "$id" "$f"; then print "⬇️  pulled  ${f:t}"; _n_save_state "$id" "$f"; pulled+=1
      else print -u2 "pull failed: ${f:t}"; fi
    fi
  done < <(find "$dir" -type f -name '*.md' -not -path '*/.notion/*' 2>/dev/null)
  print "notion: sync done — ${pushed} pushed, ${pulled} pulled, ${conflicts} conflicts, ${skipped} untracked"
}
