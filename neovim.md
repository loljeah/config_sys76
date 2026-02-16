# Neovim Cheatsheet

## Modes

| Key | Mode | Description |
|-----|------|-------------|
| `Esc` | Normal | Default mode, navigation and commands |
| `i` | Insert | Insert text before cursor |
| `a` | Insert | Insert text after cursor |
| `I` | Insert | Insert at beginning of line |
| `A` | Insert | Insert at end of line |
| `o` | Insert | New line below, enter insert |
| `O` | Insert | New line above, enter insert |
| `v` | Visual | Character selection |
| `V` | Visual Line | Line selection |
| `Ctrl+v` | Visual Block | Block/column selection |
| `:` | Command | Enter command mode |
| `R` | Replace | Overwrite text |

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
| `0` | Beginning of line |
| `^` | First non-blank character |
| `$` | End of line |
| `gg` | First line of file |
| `G` | Last line of file |
| `5G` or `:5` | Go to line 5 |
| `%` | Jump to matching bracket |

### Screen Movement
| Key | Action |
|-----|--------|
| `Ctrl+f` | Page down |
| `Ctrl+b` | Page up |
| `Ctrl+d` | Half page down |
| `Ctrl+u` | Half page up |
| `H` | Top of screen |
| `M` | Middle of screen |
| `L` | Bottom of screen |
| `zz` | Center cursor on screen |
| `zt` | Cursor to top of screen |
| `zb` | Cursor to bottom of screen |

### Jumps
| Key | Action |
|-----|--------|
| `Ctrl+o` | Jump back (older position) |
| `Ctrl+i` | Jump forward (newer position) |
| `` ` ` `` | Jump to last edit position |
| `''` | Jump to last jump position |
| `gd` | Go to definition |
| `gf` | Go to file under cursor |

---

## Editing

### Delete (cut)
| Key | Action |
|-----|--------|
| `x` | Delete character under cursor |
| `X` | Delete character before cursor |
| `dd` | Delete entire line |
| `D` | Delete to end of line |
| `dw` | Delete word |
| `d$` | Delete to end of line |
| `d0` | Delete to beginning of line |
| `dgg` | Delete to beginning of file |
| `dG` | Delete to end of file |
| `d5d` or `5dd` | Delete 5 lines |
| `diw` | Delete inner word |
| `daw` | Delete a word (including space) |
| `di"` | Delete inside quotes |
| `da"` | Delete around quotes (including quotes) |
| `di(` | Delete inside parentheses |
| `di{` | Delete inside braces |
| `dit` | Delete inside HTML tag |

### Change (delete and enter insert mode)
| Key | Action |
|-----|--------|
| `cc` | Change entire line |
| `C` | Change to end of line |
| `cw` | Change word |
| `ciw` | Change inner word |
| `ci"` | Change inside quotes |
| `ci(` | Change inside parentheses |
| `ct.` | Change until period |

### Copy (yank)
| Key | Action |
|-----|--------|
| `yy` | Yank (copy) line |
| `Y` | Yank line (same as yy) |
| `yw` | Yank word |
| `y$` | Yank to end of line |
| `yiw` | Yank inner word |
| `yi"` | Yank inside quotes |
| `5yy` | Yank 5 lines |

### Paste
| Key | Action |
|-----|--------|
| `p` | Paste after cursor |
| `P` | Paste before cursor |
| `]p` | Paste with auto-indent |

### Undo/Redo
| Key | Action |
|-----|--------|
| `u` | Undo |
| `Ctrl+r` | Redo |
| `.` | Repeat last command |

### Indent
| Key | Action |
|-----|--------|
| `>>` | Indent line |
| `<<` | Unindent line |
| `>` | Indent selection (visual mode) |
| `<` | Unindent selection (visual mode) |
| `=` | Auto-indent selection |
| `gg=G` | Auto-indent entire file |

### Case
| Key | Action |
|-----|--------|
| `~` | Toggle case of character |
| `gUU` | Uppercase entire line |
| `guu` | Lowercase entire line |
| `gUw` | Uppercase word |
| `guw` | Lowercase word |

### Join/Split Lines
| Key | Action |
|-----|--------|
| `J` | Join line below to current |
| `gJ` | Join without space |

---

## Search and Replace

### Search
| Key | Action |
|-----|--------|
| `/pattern` | Search forward |
| `?pattern` | Search backward |
| `n` | Next match |
| `N` | Previous match |
| `*` | Search word under cursor (forward) |
| `#` | Search word under cursor (backward) |
| `:noh` | Clear search highlight |

### Search Examples
```vim
/hello          " Find 'hello'
/hello\c        " Case insensitive search
/hello\C        " Case sensitive search
/^hello         " Lines starting with 'hello'
/hello$         " Lines ending with 'hello'
/hel.o          " . matches any character
/hel.*o         " .* matches any characters
/\vhello|world  " 'hello' OR 'world' (very magic)
```

### Replace (Substitute)
| Command | Action |
|---------|--------|
| `:s/old/new/` | Replace first occurrence on line |
| `:s/old/new/g` | Replace all on current line |
| `:%s/old/new/g` | Replace all in file |
| `:%s/old/new/gc` | Replace all with confirmation |
| `:5,10s/old/new/g` | Replace in lines 5-10 |
| `:'<,'>s/old/new/g` | Replace in visual selection |
| `:%s/old/new/gi` | Replace all, case insensitive |

### Replace Examples
```vim
:%s/foo/bar/g           " Replace all 'foo' with 'bar'
:%s/foo/bar/gc          " Replace with confirmation (y/n/a/q)
:%s/\s\+$//g            " Remove trailing whitespace
:%s/^/# /g              " Add '# ' to start of every line
:%s/$/;/g               " Add ';' to end of every line
:%s/\n//g               " Remove all newlines
:10,20s/old/new/g       " Replace only in lines 10-20
```

---

## Visual Mode

| Key | Action |
|-----|--------|
| `v` | Start character-wise visual |
| `V` | Start line-wise visual |
| `Ctrl+v` | Start block visual |
| `o` | Move to other end of selection |
| `gv` | Reselect last visual selection |
| `>` | Indent selection |
| `<` | Unindent selection |
| `y` | Yank selection |
| `d` | Delete selection |
| `c` | Change selection |
| `~` | Toggle case |
| `u` | Lowercase |
| `U` | Uppercase |
| `:` | Command on selection |

### Block Visual (Column Editing)
1. `Ctrl+v` to enter block mode
2. Select column with `j/k`
3. `I` to insert at start of each line
4. Type text
5. `Esc` to apply to all lines

---

## Files and Buffers

### File Operations
| Command | Action |
|---------|--------|
| `:w` | Save file |
| `:w filename` | Save as filename |
| `:q` | Quit |
| `:q!` | Quit without saving |
| `:wq` or `:x` | Save and quit |
| `ZZ` | Save and quit |
| `ZQ` | Quit without saving |
| `:e filename` | Open file |
| `:e!` | Reload file (discard changes) |
| `:r filename` | Insert file contents |

### Buffers
| Command | Action |
|---------|--------|
| `:ls` | List buffers |
| `:bn` | Next buffer |
| `:bp` | Previous buffer |
| `:b3` | Go to buffer 3 |
| `:bd` | Close buffer |
| `:bd!` | Force close buffer |

### Windows (Splits)
| Key | Action |
|-----|--------|
| `:sp` or `Ctrl+w s` | Horizontal split |
| `:vsp` or `Ctrl+w v` | Vertical split |
| `Ctrl+w h/j/k/l` | Navigate splits |
| `Ctrl+w H/J/K/L` | Move window |
| `Ctrl+w =` | Equal size splits |
| `Ctrl+w _` | Maximize height |
| `Ctrl+w \|` | Maximize width |
| `Ctrl+w +/-` | Increase/decrease height |
| `Ctrl+w >/<` | Increase/decrease width |
| `Ctrl+w q` | Close window |
| `Ctrl+w o` | Close all other windows |

### Tabs
| Command | Action |
|---------|--------|
| `:tabnew` | New tab |
| `:tabnew file` | Open file in new tab |
| `gt` | Next tab |
| `gT` | Previous tab |
| `:tabclose` | Close tab |
| `:tabonly` | Close other tabs |

---

## Registers

| Key | Action |
|-----|--------|
| `"ay` | Yank to register 'a' |
| `"ap` | Paste from register 'a' |
| `"+y` | Yank to system clipboard |
| `"+p` | Paste from system clipboard |
| `"*y` | Yank to selection clipboard |
| `"0p` | Paste last yank (not delete) |
| `:reg` | Show all registers |

---

## Macros

| Key | Action |
|-----|--------|
| `qa` | Start recording macro to register 'a' |
| `q` | Stop recording |
| `@a` | Play macro 'a' |
| `@@` | Repeat last macro |
| `10@a` | Run macro 'a' 10 times |

---

## Marks

| Key | Action |
|-----|--------|
| `ma` | Set mark 'a' at cursor |
| `` `a `` | Jump to mark 'a' (exact position) |
| `'a` | Jump to mark 'a' (line start) |
| `:marks` | List all marks |
| `` `. `` | Jump to last change |
| `` `" `` | Jump to position when last exited |

---

## Folding

| Key | Action |
|-----|--------|
| `zf` | Create fold (visual mode) |
| `zo` | Open fold |
| `zc` | Close fold |
| `za` | Toggle fold |
| `zR` | Open all folds |
| `zM` | Close all folds |
| `zd` | Delete fold |

---

## Useful Commands

### Line Numbers
```vim
:set number          " Show line numbers
:set relativenumber  " Relative line numbers
:set nonumber        " Hide line numbers
```

### Whitespace
```vim
:set list            " Show whitespace characters
:set nolist          " Hide whitespace characters
:%s/\s\+$//g         " Remove trailing whitespace
:retab               " Convert tabs to spaces
```

### Encoding
```vim
:set fileencoding=utf-8
:set encoding=utf-8
```

### File Info
```vim
Ctrl+g               " Show file info
g Ctrl+g             " Show detailed info (words, bytes)
```

### Spelling
```vim
:set spell           " Enable spell check
:set nospell         " Disable spell check
]s                   " Next misspelled word
[s                   " Previous misspelled word
z=                   " Suggest corrections
zg                   " Add word to dictionary
```

### External Commands
```vim
:!command            " Run shell command
:r !command          " Insert command output
:%!sort              " Sort entire file
:%!jq .              " Format JSON with jq
```

---

## Text Objects

Format: `[operator][count][text-object]`

### Inner vs Around
- `i` = inner (excludes delimiters)
- `a` = around (includes delimiters)

### Common Text Objects
| Object | Description |
|--------|-------------|
| `w` | word |
| `W` | WORD (whitespace-delimited) |
| `s` | sentence |
| `p` | paragraph |
| `"` | double quotes |
| `'` | single quotes |
| `` ` `` | backticks |
| `(` or `)` | parentheses |
| `[` or `]` | brackets |
| `{` or `}` | braces |
| `<` or `>` | angle brackets |
| `t` | HTML/XML tag |
| `b` | block (parentheses) |
| `B` | block (braces) |

### Examples
```vim
diw     " Delete inner word
daw     " Delete a word (with space)
ci"     " Change inside double quotes
da(     " Delete around parentheses
yit     " Yank inside HTML tag
vip     " Select inner paragraph
```

---

## Multiple Cursors / Repeat

Neovim doesn't have native multiple cursors, but you can:

1. **Visual Block + Insert**
   - `Ctrl+v` select column
   - `I` or `A` to insert
   - Type text, `Esc`

2. **Search and Replace**
   - `:%s/old/new/gc` with confirmation

3. **Macro on multiple lines**
   - Record macro: `qa...q`
   - Visual select lines: `V` + motion
   - Run on selection: `:'<,'>normal @a`

4. **Global command**
   - `:g/pattern/command`
   - `:g/TODO/d` - delete all lines with TODO
   - `:g/^$/d` - delete empty lines

---

## LSP (Language Server)

If configured with nvim-lspconfig:

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gr` | Go to references |
| `gi` | Go to implementation |
| `K` | Hover documentation |
| `Ctrl+k` | Signature help |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action |
| `[d` | Previous diagnostic |
| `]d` | Next diagnostic |

---

## Quick Reference - Common Tasks

| Task | Command |
|------|---------|
| Delete line | `dd` |
| Delete 5 lines | `5dd` |
| Delete word | `dw` |
| Delete to end of line | `D` |
| Copy line | `yy` |
| Copy to system clipboard | `"+yy` |
| Paste | `p` |
| Undo | `u` |
| Redo | `Ctrl+r` |
| Search | `/pattern` |
| Replace all | `:%s/old/new/g` |
| Save | `:w` |
| Save and quit | `:wq` or `ZZ` |
| Quit without saving | `:q!` or `ZQ` |
| Go to line 50 | `50G` or `:50` |
| Go to start of file | `gg` |
| Go to end of file | `G` |
| Indent line | `>>` |
| Comment line | Depends on plugin |
| Split vertical | `:vsp` |
| Split horizontal | `:sp` |
| Navigate splits | `Ctrl+w h/j/k/l` |

---

## Exiting Vim

```
:q      " Quit (fails if unsaved changes)
:q!     " Quit without saving
:wq     " Save and quit
:x      " Save and quit (only writes if changed)
ZZ      " Save and quit
ZQ      " Quit without saving
:qa     " Quit all windows
:qa!    " Quit all without saving
:wqa    " Save all and quit
```
