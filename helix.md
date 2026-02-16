# Helix Cheatsheet

Helix uses a **selection-first** model: select text, then act on it.
This is the opposite of Vim (verb-object vs object-verb).

## Modes

| Key | Mode | Description |
|-----|------|-------------|
| `Esc` | Normal | Default mode, navigation and commands |
| `i` | Insert | Insert before selection |
| `a` | Insert | Insert after selection |
| `I` | Insert | Insert at line start |
| `A` | Insert | Insert at line end |
| `o` | Insert | New line below |
| `O` | Insert | New line above |
| `v` | Select | Extend selection |
| `:` | Command | Enter command mode |
| `r` | Replace | Replace selected character(s) |

---

## Navigation

### Basic Movement
| Key | Action |
|-----|--------|
| `h` | Left |
| `j` | Down |
| `k` | Up |
| `l` | Right |
| `w` | Next word start |
| `W` | Next WORD start (whitespace-delimited) |
| `e` | Next word end |
| `b` | Previous word start |
| `B` | Previous WORD start |
| `0` | Line start |
| `^` | First non-blank |
| `$` | Line end |
| `gg` | File start |
| `ge` | File end |
| `5g` or `:5` | Go to line 5 |
| `%` | Jump to matching bracket |

### Screen Movement
| Key | Action |
|-----|--------|
| `Ctrl+f` | Page down |
| `Ctrl+b` | Page up |
| `Ctrl+d` | Half page down |
| `Ctrl+u` | Half page up |
| `zz` | Center cursor |
| `zt` | Cursor to top |
| `zb` | Cursor to bottom |

### Jumps
| Key | Action |
|-----|--------|
| `Ctrl+o` | Jump back |
| `Ctrl+i` | Jump forward |
| `Ctrl+s` | Save position to jump list |
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gr` | Go to references |
| `gi` | Go to implementation |
| `gy` | Go to type definition |
| `ga` | Go to last accessed file |
| `gm` | Go to modified file |

---

## Selection (The Helix Way)

Helix selects first, then operates. Every movement creates/extends a selection.

### Selection Basics
| Key | Action |
|-----|--------|
| `v` | Toggle extend mode (grow selection) |
| `;` | Collapse selection to cursor |
| `Alt+;` | Flip selection direction |
| `,` | Keep only primary selection |
| `Alt+,` | Remove primary selection |
| `C` | Copy selection below (multi-cursor) |
| `Alt+C` | Copy selection above |
| `s` | Select regex in selection |
| `S` | Split selection by regex |
| `Alt+s` | Split selection on newlines |
| `&` | Align selections |
| `_` | Trim whitespace from selection |
| `x` | Select entire line |
| `X` | Extend to entire line |

### Expand Selection
| Key | Action |
|-----|--------|
| `Alt+o` | Expand selection (syntax-aware) |
| `Alt+i` | Shrink selection |
| `Alt+p` | Select parent syntax node |
| `Alt+n` | Select next sibling node |
| `Alt+e` | Move to end of parent node |

### Multi-Selection
| Key | Action |
|-----|--------|
| `C` | Add cursor below |
| `Alt+C` | Add cursor above |
| `)` | Rotate main selection forward |
| `(` | Rotate main selection backward |
| `Alt+)` | Cycle selection contents forward |
| `Alt+(` | Cycle selection contents backward |
| `,` | Keep only primary selection |
| `Alt+,` | Remove primary selection |
| `%` | Select all |

---

## Editing

### Delete
| Key | Action |
|-----|--------|
| `d` | Delete selection |
| `Alt+d` | Delete selection (no yank) |
| `c` | Change selection (delete + insert) |
| `Alt+c` | Change selection (no yank) |

### Delete Examples
```
xd        " Select line, delete
wd        " Select word, delete
ved       " Select to word end, delete
%d        " Select all, delete
```

### Yank (Copy)
| Key | Action |
|-----|--------|
| `y` | Yank selection |
| `p` | Paste after |
| `P` | Paste before |
| `R` | Replace selection with yanked |
| `Space+y` | Yank to system clipboard |
| `Space+p` | Paste from system clipboard |

### Undo/Redo
| Key | Action |
|-----|--------|
| `u` | Undo |
| `U` | Redo |
| `.` | Repeat last insert |

### Indent
| Key | Action |
|-----|--------|
| `>` | Indent |
| `<` | Unindent |
| `=` | Format selection |

### Case
| Key | Action |
|-----|--------|
| `` ` `` | Lowercase |
| `` Alt+` `` | Uppercase |
| `~` | Toggle case |

### Join Lines
| Key | Action |
|-----|--------|
| `J` | Join lines |

---

## Search

### Find
| Key | Action |
|-----|--------|
| `/` | Search forward |
| `?` | Search backward |
| `n` | Next match |
| `N` | Previous match |
| `*` | Search selection |
| `Alt+n` | Select next match (add to selection) |
| `Alt+N` | Select previous match (add to selection) |

### Find in Line
| Key | Action |
|-----|--------|
| `f<char>` | Find char forward (select to it) |
| `F<char>` | Find char backward |
| `t<char>` | Find char forward (select until it) |
| `T<char>` | Find char backward (until) |
| `Alt+.` | Repeat last find |

### Selection Search
| Key | Action |
|-----|--------|
| `s` | Select regex matches in selection |
| `S` | Split selection by regex |
| `K` | Keep selections matching regex |
| `Alt+K` | Remove selections matching regex |

---

## Search and Replace

```
:%s/old/new/g        " Replace all in file
:s/old/new/g         " Replace in selection
```

Or the Helix way:
1. `%` - Select all
2. `s` - Type regex pattern to find
3. `c` - Change (type replacement)

### Example: Replace "foo" with "bar"
```
%         " Select entire file
sfoo      " Select all 'foo' matches
cbar      " Change to 'bar'
Esc       " Exit insert mode
```

---

## Text Objects

### Match Mode (`m`)
| Key | Action |
|-----|--------|
| `mm` | Select matching bracket pair |
| `ms<char>` | Surround selection with char |
| `mr<from><to>` | Replace surrounding |
| `md<char>` | Delete surrounding |

### Select Around/Inside (`[` / `]`)

Press `mi` (match inside) or `ma` (match around) then:

| Key | Object |
|-----|--------|
| `w` | word |
| `W` | WORD |
| `p` | paragraph |
| `(` `)` `b` | parentheses |
| `{` `}` `B` | braces |
| `[` `]` | brackets |
| `<` `>` | angle brackets |
| `"` | double quotes |
| `'` | single quotes |
| `` ` `` | backticks |
| `t` | HTML tag |
| `a` | argument |
| `c` | comment |
| `f` | function |
| `T` | type/class |

### Examples
```
miw       " Select inner word
ma"       " Select around quotes (including quotes)
mi(       " Select inside parentheses
mif       " Select inside function
```

---

## Multiple Cursors

| Key | Action |
|-----|--------|
| `C` | Add cursor below |
| `Alt+C` | Add cursor above |
| `s` | Select regex matches (creates cursors) |
| `,` | Keep only primary cursor |
| `Alt+,` | Remove primary cursor |
| `(` / `)` | Cycle between cursors |
| `%` | Select all, then `s` for multi-cursor |

### Multi-cursor Example
```
%             " Select all
shello        " Select all 'hello' occurrences
cworld        " Change all to 'world'
Esc           " Done
```

---

## Space Menu (Leader)

Press `Space` for the leader menu:

| Key | Action |
|-----|--------|
| `Space f` | File picker |
| `Space F` | File picker (cwd) |
| `Space b` | Buffer picker |
| `Space j` | Jump list |
| `Space s` | Symbol picker |
| `Space S` | Workspace symbols |
| `Space g` | Debug menu |
| `Space k` | Hover docs |
| `Space r` | Rename symbol |
| `Space a` | Code actions |
| `Space d` | Diagnostics |
| `Space D` | Workspace diagnostics |
| `Space '` | Last picker |
| `Space w` | Window menu |
| `Space y` | Yank to clipboard |
| `Space p` | Paste from clipboard |
| `Space R` | Replace from clipboard |
| `Space /` | Global search |
| `Space ?` | Command palette |

---

## Window Management

Press `Ctrl+w` or `Space w`:

| Key | Action |
|-----|--------|
| `w v` or `Ctrl+w v` | Vertical split |
| `w s` or `Ctrl+w s` | Horizontal split |
| `w h/j/k/l` | Navigate windows |
| `w H/J/K/L` | Move window |
| `w q` | Close window |
| `w o` | Close other windows |
| `Ctrl+w w` | Cycle windows |

---

## Buffers

| Command | Action |
|---------|--------|
| `:o file` or `:open file` | Open file |
| `:w` | Save |
| `:w file` | Save as |
| `:q` | Quit |
| `:q!` | Quit without saving |
| `:wq` or `:x` | Save and quit |
| `:bc` or `:buffer-close` | Close buffer |
| `:bn` | Next buffer |
| `:bp` | Previous buffer |
| `Space b` | Buffer picker |

---

## Goto Menu (`g`)

| Key | Action |
|-----|--------|
| `gg` | Go to file start |
| `ge` | Go to file end |
| `gh` | Go to line start |
| `gl` | Go to line end |
| `gs` | Go to first non-blank |
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gy` | Go to type definition |
| `gr` | Go to references |
| `gi` | Go to implementation |
| `ga` | Go to last accessed file |
| `gm` | Go to last modified file |
| `gn` | Go to next buffer |
| `gp` | Go to previous buffer |
| `g.` | Go to last change |

---

## View Menu (`z`)

| Key | Action |
|-----|--------|
| `zz` | Center line |
| `zt` | Line to top |
| `zb` | Line to bottom |
| `zk` | Scroll up |
| `zj` | Scroll down |
| `zh` | Scroll left |
| `zl` | Scroll right |

---

## LSP Features

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gr` | Go to references |
| `gi` | Go to implementation |
| `gy` | Go to type definition |
| `Space k` | Hover documentation |
| `Space r` | Rename symbol |
| `Space a` | Code actions |
| `Space s` | Document symbols |
| `Space S` | Workspace symbols |
| `]d` | Next diagnostic |
| `[d` | Previous diagnostic |
| `Space d` | Show diagnostics |

---

## Shell Commands

| Command | Action |
|---------|--------|
| `:sh cmd` | Run shell command |
| `:pipe cmd` | Pipe selection through command |
| `:pipe-to cmd` | Pipe selection to command (no replace) |
| `:insert-output cmd` | Insert command output |
| `:append-output cmd` | Append command output |

### Examples
```
:sh ls                    " Run ls
:pipe sort                " Sort selected lines
:pipe jq .                " Format JSON
:%pipe sort -u            " Sort entire file, unique
```

---

## Macros

| Key | Action |
|-----|--------|
| `Q` | Start/stop recording |
| `q` | Play macro |
| `Alt+Q` | Play macro until end of file |

---

## Registers

| Key | Action |
|-----|--------|
| `"<reg>` | Select register for next yank/paste |
| `"+` | System clipboard register |
| `"_` | Black hole register (discard) |

### Examples
```
"ay       " Yank to register 'a'
"ap       " Paste from register 'a'
"+y       " Yank to system clipboard
"+p       " Paste from clipboard
```

---

## Configuration

Config file: `~/.config/helix/config.toml`

```toml
theme = "onedark"

[editor]
line-number = "relative"
mouse = true
cursorline = true
auto-save = true
idle-timeout = 400

[editor.cursor-shape]
insert = "bar"
normal = "block"
select = "underline"

[editor.file-picker]
hidden = false

[editor.lsp]
display-messages = true
display-inlay-hints = true

[editor.indent-guides]
render = true
character = "│"

[keys.normal]
C-s = ":w"
C-q = ":q"
```

Languages: `~/.config/helix/languages.toml`

```toml
[[language]]
name = "python"
auto-format = true
formatter = { command = "black", args = ["-"] }

[[language]]
name = "nix"
auto-format = true
formatter = { command = "nixfmt" }
```

---

## Common Tasks Quick Reference

| Task | Command |
|------|---------|
| Delete line | `xd` |
| Delete 5 lines | `5xd` or `x....d` (select 5 lines) |
| Delete word | `wd` |
| Delete to end of line | `vgld` or `t<Enter>d` |
| Copy line | `xy` |
| Copy to clipboard | `x Space y` |
| Paste | `p` |
| Paste from clipboard | `Space p` |
| Undo | `u` |
| Redo | `U` |
| Search | `/pattern` |
| Replace all | `%sfoo` then `cbar` |
| Save | `:w` |
| Save and quit | `:wq` or `:x` |
| Quit without saving | `:q!` |
| Go to line 50 | `50g` or `:50` |
| Go to file start | `gg` |
| Go to file end | `ge` |
| Indent | `>` |
| Format | `=` |
| Split vertical | `:vsplit` or `Space w v` |
| Split horizontal | `:hsplit` or `Space w s` |
| Open file picker | `Space f` |
| Open buffer picker | `Space b` |
| Command palette | `Space ?` |

---

## Helix vs Vim Mental Model

| Vim (verb-object) | Helix (object-verb) |
|-------------------|---------------------|
| `dw` delete word | `wd` select word, delete |
| `d$` delete to EOL | `vgl d` or `t<Enter>d` |
| `dd` delete line | `xd` select line, delete |
| `ci"` change in quotes | `mi"c` match inside quotes, change |
| `yy` yank line | `xy` select line, yank |
| `5dd` delete 5 lines | `5xd` or select then `d` |

The Helix way: **See what you're affecting before acting.**

---

## Getting Help

```
:tutor          " Built-in tutorial
:help           " Help
:health         " Check LSP/language setup
:config-open    " Open config file
:log-open       " Open log file
```
