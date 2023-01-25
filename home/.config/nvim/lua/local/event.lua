--- vim event constants
---
---@type table<string, local.vim.event>
local e = {}

---@alias local.vim.event string

setmetatable(e, {
  __index = function(_, key)
    error("unknown vim event: " .. tostring(key))
  end,
})

--- Just after creating a new buffer which is added to the buffer list, or adding a buffer to the buffer list, a buffer in the buffer list was renamed.
---
--- Not triggered for the initial buffers created during startup.
---
--- Before `BufEnter`.
---
--- NOTE: Current buffer "%" may be different from the buffer being created "<afile>".
---
e.BufAdd = "BufAdd"

--- Before deleting a buffer from the buffer list.
---
--- The BufUnload may be called first (if the buffer was loaded).
---
--- Also used just before a buffer in the buffer list is renamed.
---
--- NOTE: Current buffer "%" may be different from the buffer being deleted "<afile>" and "<abuf>".
---
--- Do not change to another buffer.
e.BufDelete = "BufDelete"

--- After entering a buffer. Useful for setting options for a file type.
---
--- Also executed when starting to edit a buffer.
---
--- After `BufAdd`.
--- After `BufReadPost`.
e.BufEnter = "BufEnter"

--- After changing the name of the current buffer with the ":file" or ":saveas" command.
e.BufFilePost = "BufFilePost"

--- Before changing the name of the current buffer with the ":file" or ":saveas" command.
e.BufFilePre = "BufFilePre"

--- Before a buffer becomes hidden: when there are no longer windows that show the buffer, but the buffer is not unloaded or deleted.
---
--- Not used for ":qa" or ":q" when exiting Vim.
---
--- NOTE: current buffer "%" may be different from the buffer being unloaded "<afile>".
e.BufHidden = "BufHidden"

--- Before leaving to another buffer. Also when leaving or closing the current window and the new current window is not for the same buffer.
---
--- Not used for ":qa" or ":q" when exiting Vim.
e.BufLeave = "BufLeave"

--- After the `'modified'` value of a buffer has been changed.
e.BufModifiedSet = "BufModifiedSet"

--- Just after creating a new buffer. Also used just after a buffer has been renamed.
---
--- When the buffer is added to the buffer list `BufAdd` will be triggered too.
---
--- NOTE: Current buffer "%" may be different from the buffer being created "<afile>".
e.BufNew = "BufNew"

--- When starting to edit a file that doesn't exist. Can be used to read in a skeleton file.
e.BufNewFile = "BufNewFile"

--- When starting to edit a new buffer, after reading the file into the buffer, before processing modelines.
---
--- See `BufWinEnter` to do something after processing modelines.
---
--- Also triggered:
--.
---  - when writing an unnamed buffer in a way that the buffer gets a name
--.
---  - after successfully recovering a file
--.
---  - for the "filetypedetect" group when executing ":filetype detect"
---
--- Not triggered:
--.
---  - for the `:read file` command
--.
---  - when the file doesn't exist
e.BufRead = "BufRead"

--- When starting to edit a new buffer, after reading the file into the buffer, before processing modelines.
---
--- See `BufWinEnter` to do something after processing modelines.
---
--- Also triggered:
--.
---  - when writing an unnamed buffer in a way that the buffer gets a name
--.
---  - after successfully recovering a file
--.
---  - for the "filetypedetect" group when executing ":filetype detect"
---
--- Not triggered:
--.
---  - for the `:read file` command
--.
---  - when the file doesn't exist
e.BufReadPost = "BufReadPost"


--- Before starting to edit a new buffer.
---
--- Should read the file into the buffer. `Cmd-event`
e.BufReadCmd = "BufReadCmd"

--- When starting to edit a new buffer, before reading the file into the buffer.
---
--- Not used if the file doesn't exist.
e.BufReadPre = "BufReadPre"

--- Before unloading a buffer, when the text in the buffer is going to be freed.
---
--- After `BufWritePost`.
--- Before `BufDelete`.
---
--- Triggers for all loaded buffers when Vim is going to exit.
---
--- NOTE: Current buffer "%" may be different from the buffer being unloaded "<afile>".
---
--- Do not switch buffers or windows!
---
--- Not triggered when exiting and v:dying is 2 or more.
e.BufUnload = "BufUnload"

--- After a buffer is displayed in a window.
---
--- This may be when the buffer is loaded (after processing modelines) or when a hidden buffer
--- is displayed (and is no longer hidden).
---
--- Not triggered for `:split` without arguments, since the buffer does not change, or :split with a file already open in a window.
---
--- Triggered for ":split" with the name of the current buffer, since it reloads that buffer.
e.BufWinEnter = "BufWinEnter"

--- Before a buffer is removed from a window.
---
--- Not when it's still visible in another window.
---
--- Also triggered when exiting.
---
--- Before `BufUnload`, `BufHidden`.
---
--- NOTE: Current buffer "%" may be different from the buffer being unloaded "<afile>".
---
--- Not triggered when exiting and v:dying is 2 or more.
e.BufWinLeave = "BufWinLeave"

--- Before completely deleting a buffer.
---
--- The `BufUnload` and `BufDelete` events may be called first (if the buffer was loaded and was in the
--- buffer list).
---
--- Also used just before a buffer is renamed (also when it's not in the buffer list).
---
--- NOTE: Current buffer "%" may be different from the buffer being deleted "<afile>".
---
--- Do not change to another buffer.
e.BufWipeout = "BufWipeout"

--- Before writing the whole buffer to a file.
e.BufWrite = "BufWrite"

--- Before writing the whole buffer to a file.
e.BufWritePre = "BufWritePre"

--- Before writing the whole buffer to a file.
---
--- Should do the writing of the file and reset 'modified' if successful, unless '+' is in 'cpo' and writing to another file `cpo-+`.
---
--- The buffer contents should not be changed.
---
--- When the command resets 'modified' the undo information is adjusted to mark older undo states as 'modified', like `:write` does.
---
--- |Cmd-event`
e.BufWriteCmd = "BufWriteCmd"

--- After writing the whole buffer to a file (should undo the commands for `BufWritePre`).
e.BufWritePost = "BufWritePost"

--- State of channel changed, for instance the client of a RPC channel described itself.
---
--- Sets these `v:event| keys:
--- info
--- See `nvim_get_chan_info()` for the format of
--- the info Dictionary.
e.ChanInfo = "ChanInfo"

--- Just after a channel was opened.
---
--- Sets these `v:event` keys:
--.
---  - info
---
--- See `nvim_get_chan_info()` for the format of the info Dictionary.
e.ChanOpen = "ChanOpen"

--- When a user command is used but it isn't defined.
---
--- Useful for defining a command only when it's used.
---
--- The pattern is matched against the command name.
---
--- Both <amatch> and <afile> expand to the command name.
---
--- NOTE: Autocompletion won't work until the command is defined.
---
--- An alternative is to always define the user command and have it invoke an autoloaded function.
---
--- See `autoload`.
e.CmdUndefined = "CmdUndefined"

--- After a change was made to the text inside command line.
---
--- Be careful not to mess up the command line, it may cause Vim to lock up.
---
--- <afile> expands to the `cmdline-char`.
e.CmdlineChanged = "CmdlineChanged"

--- After entering the command-line (including non-interactive use of ":" in a mapping: use `<Cmd>` instead to avoid this).
---
--- <afile> expands to the `cmdline-char`.
---
--- Sets these `v:event` keys:
---   - `cmdlevel`
---   - `cmdtype`
e.CmdlineEnter = "CmdlineEnter"

--- Before leaving the command-line (including non-interactive use of ":" in a mapping: use `<Cmd>` instead to avoid this).
---
--- <afile> expands to the `cmdline-char`.
---
--- Sets these `v:event` keys:
---   - `abort` (mutable)
---   - `cmdlevel`
---   - `cmdtype`
---
--- Note: `abort` can only be changed from false to true: cannot execute an already aborted cmdline by changing it to false.
e.CmdlineLeave = "CmdlineLeave"

--- After entering the command-line window.
---
--- Useful for setting options specifically for this special type of window.
---
--- <afile> expands to a single character, indicating the type of command-line.
---
--- `cmdwin-char`
e.CmdwinEnter = "CmdwinEnter"

--- Before leaving the command-line window.
---
--- Useful to clean up any global setting done with CmdwinEnter.
---
--- <afile> expands to a single character, indicating the type of command-line.
---
--- `cmdwin-char`
e.CmdwinLeave = "CmdwinLeave"

--- After loading a color scheme.
---
--- Not triggered if the color scheme is not found.
---
--- The pattern is matched against the colorscheme name.
---
--- <afile> can be used for the name of the actual file where this option was set, and <amatch> for the new colorscheme name.
e.ColorScheme = "ColorScheme"

--- Before loading a color scheme.
---
--- Useful to setup removing things added by a color scheme, before another one is loaded.
e.ColorSchemePre = "ColorSchemePre"

--- After each time the Insert mode completion menu changed.
---
--- Not fired on popup menu hide, use `CompleteDonePre` or `CompleteDone` for that.
---
--- Sets these `v:event` keys:
---   - `completed_item` ->  See `complete-items`.
---   - `height`         ->  nr of items visible
---   - `width`          ->  screen cells
---   - `row`            ->  top screen row
---   - `col`            ->  leftmost screen column
---   - `size`           ->  total nr of items
---   - `scrollbar`      ->  TRUE if visible
---
--- Non-recursive (event cannot trigger itself).
---
--- Cannot change the text. `textlock`
---
--- The size and position of the popup are also available by calling `pum_getpos()`.
e.CompleteChanged = "CompleteChanged"

--- After Insert mode completion is done.
---
--- Either when something was completed or abandoning completion.
---
--- `complete_info()` can be used, the info is cleared after triggering CompleteDonePre.
---
--- The `v:completed_item` variable contains information about the completed item.
e.CompleteDonePre = "CompleteDonePre"

--- After Insert mode completion is done.
---
--- Either when something was completed or abandoning completion.
---
--- `complete_info()` cannot be used, the info is cleared before triggering CompleteDone.
---
--- Use CompleteDonePre if you need it.
---
--- `v:completed_item` gives the completed item.
e.CompleteDone = "CompleteDone"

--- When the user doesn't press a key for the time specified with 'updatetime'.
---
--- Not triggered until the user has pressed a key (i.e. doesn't fire every 'updatetime' ms if you leave Vim to
--- make some coffee. :.
---
--- See `CursorHold-example` for previewing tags.
---
--- This event is only triggered in Normal mode.
--- It is not triggered when waiting for a command argument to be typed, or a movement after an
--- operator.
---
--- While recording the `CursorHold` event is not triggered.
---
--- Internally the autocommand is triggered by the <CursorHold> key.
--- In an expression mapping `getchar()` may see this character.
---
--- Note: Interactive commands cannot be used for this event.
--- There is no hit-enter prompt, the screen is updated directly (when needed).
---
--- Note: In the future there will probably be another option to set the time.
---
--- Hint: to force an update of the status lines use:
--- ```vim
--- :let &ro = &ro
--- ```
e.CursorHold = "CursorHold"

--- Like CursorHold, but in Insert mode.
--- Not triggered when waiting for another key, e.g. after CTRL-V, and not in CTRL-X mode
e.CursorHoldI = "CursorHoldI"

--- After the cursor was moved in Normal or Visual mode or to another window.
---
--- Also when the text of the cursor line has been changed, e.g. with "x", "rx" or "p".
---
--- Not always triggered when there is typeahead, while executing commands in a script file, or when an operator is pending.
--- Always triggered when moving to another window.
---
--- For an example see `match-parens`.
---
--- Note: Cannot be skipped with `:noautocmd`.
---
--- Careful: This is triggered very often, don't do anything that the user does not expect or that is slow.
e.CursorMoved = "CursorMoved"

--- After the cursor was moved in Insert mode.
---
--- Not triggered when the popup menu is visible.
---
--- Otherwise the same as CursorMoved.
e.CursorMovedI = "CursorMovedI"

--- After diffs have been updated.
---
--- Depending on what kind of diff is being used (internal or external) this can be triggered on every change or when doing |:diffupdate`.
e.DiffUpdated = "DiffUpdated"

--- After the current directory was changed.
---
--- The pattern can be:
---  - "window"  -> trigger on `:lcd`
---  - "tabpage" -> trigger on `:tcd`
---  - "global"  -> trigger on `:cd`
---  - "auto"    -> trigger on `autochdir`
---
--- Sets these `v:event` keys:
---   - `cwd`            -> current working directory
---   - `scope`          -> "global", "tabpage", "window"
---   - `changed_window` -> v:true if we fired the event switching window (or tab)
---
--- <afile> is set to the new directory name.
---
--- Non-recursive (event cannot trigger itself).
e.DirChanged = "DirChanged"

--- When the `current-directory` is going to be changed, as with `DirChanged`.
---
--- The pattern is like with `DirChanged`.
---
--- Sets these `v:event` keys:
---   - `directory`      -> new working directory
---   - `scope`          -> "global", "tabpage", "window"
---   - `changed_window` -> `v:true` if we fired the event switching window (or tab)
---
--- <afile> is set to the new directory name.
---
--- Non-recursive (event cannot trigger itself).
e.DirChangedPre = "DirChangedPre"

--- When using `:quit`, `:wq` in a way it makes Vim exit, or using `:qall`, just after `QuitPre`.
---
--- Can be used to close any non-essential window.
---
--- Exiting may still be cancelled if there is a modified buffer that isn't automatically saved, use `VimLeavePre` for really exiting.
---
--- See also `QuitPre`, `WinClosed`.
e.ExitPre = "ExitPre"

--- Before appending to a file.
---
--- Should do the appending to the file.
---
--- Use the '[ and '] marks for the range of lines. `Cmd-event`
e.FileAppendCmd = "FileAppendCmd"

--- After appending to a file.
e.FileAppendPost = "FileAppendPost"

--- Before appending to a file.
---
--- Use the '[ and '] marks for the range of lines.
e.FileAppendPre = "FileAppendPre"

--- Before making the first change to a read-only file.
---
--- Can be used to checkout the file from a source control system.
---
--- Not triggered when the change was caused by an autocommand.
---
--- Triggered when making the first change in a buffer or the first change after 'readonly' was set, just before the change is applied to the text.
---
--- WARNING: If the autocommand moves the cursor the effect of the change is undefined.
---
--- ## E788
--- Cannot switch buffers.
--- You can reload the buffer but not edit another one.
---
--- ## E881
--- If the number of lines changes saving for undo may fail and the change will be aborted.
e.FileChangedRO = "FileChangedRO"

--- When Vim notices that the modification time of a file has changed since editing started.
---
--- Also when the file attributes of the file change or when the size of the file changes.
---
--- Triggered for each changed file, after:
---   - executing a shell command
---   - `:checktime`
---   - `FocusGained`
---
--- Not used when `autoread` is set and the buffer was not changed.
---
--- If a `FileChangedShell` autocommand exists the warning message and prompt is not given.
---
--- `v:fcs_reason` indicates what happened.
--- Set v:fcs_choice` to control what happens next.
---
--- NOTE: Current buffer "%" may be different from the buffer that was changed "<afile>".
e.FileChangedShell = "FileChangedShell"

--- After handling a file that was changed outside of Vim.
---
--- Can be used to update the statusline.
e.FileChangedShellPost = "FileChangedShellPost"

--- Before reading a file with a ":read" command.
---
--- Should do the reading of the file. `Cmd-event`
e.FileReadCmd = "FileReadCmd"

--- After reading a file with a ":read" command.
---
--- Note that Vim sets the '[ and '] marks to the first and last line of the read.
---
--- This can be used to operate on the lines just read.
e.FileReadPost = "FileReadPost"

--- Before reading a file with a ":read" command.
e.FileReadPre = "FileReadPre"

--- When the 'filetype' option has been set.
---
--- The pattern is matched against the filetype.
---
--- <afile> is the name of the file where this option was set.
--- <amatch> is the new value of 'filetype'.
---
--- Cannot switch windows or buffers.
---
--- See `filetypes`.
e.FileType = "FileType"

--- Before writing to a file, when not writing the whole buffer.
---
--- Should do the writing to the file.
--- Should not change the buffer.
---
--- Use the '[ and '] marks for the range of lines.
---
--- `Cmd-event`
e.FileWriteCmd = "FileWriteCmd"

--- After writing to a file, when not writing the whole buffer.
e.FileWritePost = "FileWritePost"

--- Before writing to a file, when not writing the whole buffer.
---
--- Use the '[ and '] marks for the range of lines.
e.FileWritePre = "FileWritePre"

--- After reading a file from a filter command.
---
--- Vim checks the pattern against the name of the current buffer as with FilterReadPre.
---
--- Not triggered when 'shelltemp' is off.
e.FilterReadPost = "FilterReadPost"

--- Before reading a file from a filter command.
---
--- Vim checks the pattern against the name of the current buffer, not the name of the temporary file that is the output of the filter command.
---
--- Not triggered when 'shelltemp' is off.
e.FilterReadPre = "FilterReadPre"

--- After writing a file for a filter command or making a diff with an external diff (see `DiffUpdated` for internal diff).
---
--- Vim checks the pattern against the name of the current buffer as with FilterWritePre.
---
--- Not triggered when 'shelltemp' is off.
e.FilterWritePost = "FilterWritePost"

--- Before writing a file for a filter command or making a diff with an external diff.
---
--- Vim checks the pattern against the name of the current buffer, not the name of the temporary file that is the output of the filter command.
---
--- Not triggered when 'shelltemp' is off.
e.FilterWritePre = "FilterWritePre"

--- Nvim got focus.
e.FocusGained = "FocusGained"

--- Nvim lost focus.
---
--- Also (potentially) when a GUI dialog pops up.
e.FocusLost = "FocusLost"

--- When a user function is used but it isn't defined.
---
--- Useful for defining a function only when it's used.
---
--- The pattern is matched against the function name.
---
--- Both <amatch> and <afile> are set to the name of the function.
---
--- NOTE: When writing Vim scripts a better alternative is to use an autoloaded function.
---
--- See `autoload-functions`.
e.FuncUndefined = "FuncUndefined"

--- After a UI connects via `nvim_ui_attach()`, or after builtin TUI is started, after `VimEnter`.
---
--- Sets these `v:event` keys:
---   - chan: 0 for builtin TUI
---           1 for `--embed`
---           `channel-id` of the UI otherwise
e.UIEnter = "UIEnter"

--- After a UI disconnects from Nvim, or after builtin TUI is stopped, after `VimLeave`.
---
--- Sets these `v:event` keys:
---   - chan: 0 for builtin TUI
---           1 for `--embed`
---           `channel-id` of the UI otherwise
e.UILeave = "UILeave"

--- When typing <Insert> while in Insert or Replace mode.
---
--- The `v:insertmode` variable indicates the new mode.
---
--- Be careful not to move the cursor or do anything else that the user does not expect.
e.InsertChange = "InsertChange"

--- When a character is typed in Insert mode, before inserting the char.
---
--- The `v:char` variable indicates the char typed and can be changed during the event to insert a different character.
---
--- When `v:char` is set to more than one character this text is inserted literally.
---
--- Cannot change the text. `textlock`
---
--- Not triggered when 'paste' is set.
e.InsertCharPre = "InsertCharPre"

--- Just before starting Insert mode.
---
--- Also for Replace mode and Virtual Replace mode.
---
--- The `v:insertmode` variable indicates the mode.
---
--- Be careful not to do anything else that the user does not expect.
---
--- The cursor is restored afterwards.
---
--- If you do not want that set `v:char` to a non-empty string.
e.InsertEnter = "InsertEnter"

--- Just before leaving Insert mode.
---
--- Also when using CTRL-O `i_CTRL-O`.
---
--- Be careful not to change mode or use `:normal`, it will likely cause trouble.
e.InsertLeavePre = "InsertLeavePre"

--- Just after leaving Insert mode.
---
--- Also when using CTRL-O `i_CTRL-O`.
--- But not for `i_CTRL-C`.
e.InsertLeave = "InsertLeave"

--- Just before showing the popup menu (under the right mouse button).
---
--- Useful for adjusting the menu for what is under the cursor or mouse pointer.
---
--- The pattern is matched against one or two characters representing the mode:
---   - `n`  -> Normal
---   - `v`  -> Visual
---   - `o`  -> Operator-pending
---   - `i`  -> Insert
---   - `c`  -> Command line
---   - `tl` -> Terminal
e.MenuPopup = "MenuPopup"

--- After changing the mode.
--- The pattern is matched against `'old_mode:new_mode'`, for example match against `*:c` to simulate `CmdlineEnter`.
---
--- The following values of `v:event` are set:
---   - `old_mode` -> The mode before it changed.
---   - `new_mode` -> The new mode as also returned by `mode()` called with a non-zero argument.
---
--- When ModeChanged is triggered, old_mode will have the value of new_mode when the event was last triggered.
---
--- This will be triggered on every minor mode change.
---
--- Usage example to use relative line numbers when entering visual mode:
---
--- ```vim
--- :au ModeChanged [vV\x16]*:* let &l:rnu = mode() =~# '^[vV\x16]'
--- :au ModeChanged *:[vV\x16]* let &l:rnu = mode() =~# '^[vV\x16]'
--- :au WinEnter,WinLeave * let &l:rnu = mode() =~# '^[vV\x16]'
--- ```
e.ModeChanged = "ModeChanged"

--- After setting an option (except during startup).
---
--- The `autocmd-pattern` is matched against the long option name.
---
--- * `<amatch>` indicates what option has been set.
--- * `v:option_type` indicates whether it's global or local scoped.
--- * `v:option_command` indicates what type of set/let command was used (follow the tag to see the table).
--- * `v:option_new` indicates the newly set value.
--- * `v:option_oldlocal` has the old local value.
--- * `v:option_oldglobal` has the old global value.
--- * `v:option_old` indicates the old option value.
--- * `v:option_oldlocal` is only set when `:set` or `:setlocal` or a `modeline` was used to set the option.
---
--- Similarly `v:option_oldglobal` is only set when `:set` or `:setglobal` was used.
---
--- Note that when setting a `global-local` string option with `:set`, then `v:option_old` is the old global value.
--- However, for all other kinds of options (local string options, global-local number options, ...) it is the old local value.
---
--- OptionSet is not triggered on startup and for the 'key' option for obvious reasons.
--
--- Usage example: Check for the existence of the directory in the 'backupdir' and 'undodir' options, create the directory if it doesn't exist yet.
---
--- Note: Do not reset the same option during this autocommand, that may break plugins. You can always use `:noautocmd` to prevent triggering OptionSet.
---
--- Non-recursive: `:set` in the autocommand does not trigger OptionSet again.
e.OptionSet = "OptionSet"

--- Before a quickfix command is run:
---
---  * `:make`
---  * `:lmake`
---  * `:grep`
---  * `:lgrep`
---  * `:grepadd`
---  * `:lgrepadd`
---  * `:vimgrep`
---  * `:lvimgrep`
---  * `:vimgrepadd`
---  * `:lvimgrepadd`
---  * `:cscope`
---  * `:cfile`
---  * `:cgetfile`
---  * `:caddfile`
---  * `:lfile`
---  * `:lgetfile`
---  * `:laddfile`
---  * `:helpgrep`
---  * `:lhelpgrep`
---  * `:cexpr`
---  * `:cgetexpr`
---  * `:caddexpr`
---  * `:cbuffer`
---  * `:cgetbuffer`
---  * `:caddbuffer`
---
--- The pattern is matched against the command being run.
---
--- When `:grep` is used but 'grepprg' is set to "internal" it still matches "grep".
---
--- This command cannot be used to set the 'makeprg' and 'grepprg' variables.
---
--- If this command causes an error, the quickfix command is not executed.
e.QuickFixCmdPre = "QuickFixCmdPre"

--- Like QuickFixCmdPre, but after a quickfix command is run, before jumping to the first location.
---
--- For `:cfile` and `:lfile` commands it is run after error file is read and before moving to the first error.
---
--- See `QuickFixCmdPost-example`.
e.QuickFixCmdPost = "QuickFixCmdPost"

--- When using `:quit`, `:wq` or `:qall`, before deciding whether it closes the current window or quits Vim.
---
--- For `:wq` the buffer is written before QuitPre is triggered.
---
--- Can be used to close any non-essential window if the current window is the last ordinary window.
---
--- See also `ExitPre`, `WinClosed`.
e.QuitPre = "QuitPre"

--- When a reply from a Vim that functions as server was received server2client().
---
--- The pattern is matched against the {serverid}.
---
--- <amatch> is equal to the {serverid} from which the reply was sent, and <afile> is the actual reply string.
---
--- Note that even if an autocommand is defined, the reply should be read with remote_read() to consume it.
e.RemoteReply = "RemoteReply"

--- After making a search with `n` or `N` if the search wraps around the document back to the start/finish respectively.
e.SearchWrapped = "SearchWrapped"

--- When a macro starts recording.
---
--- The pattern is the current file name, and `reg_recording()` is the current register that is used.
e.RecordingEnter = "RecordingEnter"

--- When a macro stops recording.
---
--- The pattern is the current file name, and `reg_recording()` is the recorded register.
---
--- `reg_recorded()` is only updated after this event.
---
--- Sets these `v:event` keys:
---   - regcontents
---   - regname
e.RecordingLeave = "RecordingLeave"

--- After loading the session file created using the `:mksession` command.
e.SessionLoadPost = "SessionLoadPost"

--- After executing a shell command with `:!cmd`, `:make` and `:grep`.
---
--- Can be used to check for any changed files.
---
--- For non-blocking shell commands, see `job-control`.
e.ShellCmdPost = "ShellCmdPost"

--- After Nvim receives a signal.
---
--- The pattern is matched against the signal name.
--- Only "SIGUSR1" and "SIGWINCH" are supported.
---
--- Example:
---
--- ```vim
--- autocmd Signal SIGUSR1 call some#func()
--- ```
e.Signal = "Signal"

--- After executing a shell command with `:{range}!cmd`, `:w !cmd` or `:r !cmd`.
---
--- Can be used to check for any changed files.
e.ShellFilterPost = "ShellFilterPost"

--- Before sourcing a vim/lua file.
---
--- <afile> is the name of the file being sourced.
e.SourcePre = "SourcePre"

--- After sourcing a vim/lua file.
---
--- <afile> is the name of the file being sourced.
---
--- Not triggered when sourcing was interrupted.
---
--- Also triggered after a SourceCmd autocommand was triggered.
e.SourcePost = "SourcePost"

--- When sourcing a vim/lua file.
---
--- <afile> is the name of the file being sourced.
---
--- The autocommand must source this file.
---
--- `Cmd-event`
e.SourceCmd = "SourceCmd"

--- When trying to load a spell checking file and it can't be found.
---
--- The pattern is matched against the language.
---
--- <amatch> is the language, 'encoding' also matters.
---
--- See `spell-SpellFileMissing`.
e.SpellFileMissing = "SpellFileMissing"

--- During startup, after reading from stdin into the buffer, before executing modelines.
e.StdinReadPost = "StdinReadPost"

--- During startup, before reading from stdin into the buffer.
e.StdinReadPre = "StdinReadPre"

--- Detected an existing swap file when starting to edit a file.
---
--- Only when it is possible to select a way to handle the situation, when Vim would ask the user what to do.
---
--- The `v:swapname` variable holds the name of the swap file found, <afile> the file being edited.
---
--- `v:swapcommand` may contain a command to be executed in the opened file.
---
--- The commands should set the `v:swapchoice` variable to a string with one character to tell Vim what should be done next:
---   - `o` -> open read-only
---   - `e` -> edit the file anyway
---   - `r` -> recover
---   - `d` -> delete the swap file
---   - `q` -> quit, don't edit the file
---   - `a` -> abort, like hitting CTRL-C
---
--- When set to an empty string the user will be asked, as if there was no SwapExists autocmd.
---
--- *E812*
---
--- Cannot change to another buffer, change the buffer name or change directory.
e.SwapExists = "SwapExists"

--- When the 'syntax' option has been set.
---
--- The pattern is matched against the syntax name.
---
--- <afile> expands to the name of the file where this option was set.
--- <amatch> expands to the new value of 'syntax'.
---
--- See `:syn-on`.
e.Syntax = "Syntax"

--- Just after entering a tab page.
---
--- After WinEnter.
---
--- Before BufEnter.
e.TabEnter = "TabEnter"

--- Just before leaving a tab page. `tab-page`
---
--- After WinLeave.
e.TabLeave = "TabLeave"

--- When creating a new tab page. `tab-page`
---
--- After WinEnter.
---
--- Before TabEnter.
e.TabNew = "TabNew"

--- After entering a new tab page. `tab-page`
---
--- After BufEnter.
e.TabNewEntered = "TabNewEntered"

--- After closing a tab page. <afile> expands to the tab page number.
e.TabClosed = "TabClosed"

--- When a `terminal` job is starting.
---
--- Can be used to configure the terminal buffer.
e.TermOpen = "TermOpen"

--- After entering `Terminal-mode`.
---
--- After TermOpen.
e.TermEnter = "TermEnter"

--- After leaving `Terminal-mode`.
---
--- After TermClose.
e.TermLeave = "TermLeave"

--- When a `terminal` job ends.
---
--- Sets these `v:event` keys:
---   - status
e.TermClose = "TermClose"

--- After the response to t_RV is received from the terminal.
---
--- The value of `v:termresponse` can be used to do things depending on the terminal version.
---
--- May be triggered halfway through another event (file I/O, a shell command, or anything else that takes time).
e.TermResponse = "TermResponse"

--- After a change was made to the text in the current buffer in Normal mode.
---
--- That is after `b:changedtick` has changed (also when that happened before the TextChanged autocommand was defined).
---
--- Not triggered when there is typeahead or when an operator is pending.
---
--- Note: Cannot be skipped with `:noautocmd`.
---
--- Careful: This is triggered very often, don't do anything that the user does not expect or that is slow.
e.TextChanged = "TextChanged"

--- After a change was made to the text in the current buffer in Insert mode.
---
--- Not triggered when the popup menu is visible.
---
--- Otherwise the same as TextChanged.
e.TextChangedI = "TextChangedI"

--- After a change was made to the text in the current buffer in Insert mode, only when the popup menu is visible.
---
--- Otherwise the same as TextChanged.
e.TextChangedP = "TextChangedP"

--- Just after a `yank` or `deleting` command, but not if the black hole register `quote_` is used nor for `setreg()`. Pattern must be *.
---
--- Sets these `v:event` keys:
---   - inclusive
---   - operator
---   - regcontents
---   - regname
---   - regtype
---   - visual
---
--- The `inclusive` flag combined with the `'[` and `']` marks can be used to calculate the precise region of the operation.
---
--- Non-recursive (event cannot trigger itself).
---
--- Cannot change the text. `textlock`
e.TextYankPost = "TextYankPost"

--- Not executed automatically.
---
--- Use `:doautocmd` to trigger this, typically for "custom events" in a plugin.
---
--- Example:
---
--- ```vim
--- :autocmd User MyPlugin echom 'got MyPlugin event'
--- :doautocmd User MyPlugin
--- ```
e.User = "User"

--- When the user presses the same key 42 times.
---
--- Just kidding! :-)
e.UserGettingBored = "UserGettingBored"

--- After doing all the startup stuff, including loading vimrc files, executing the "-c cmd" arguments, creating all windows and loading the buffers in them.
---
--- Just before this event is triggered the `v:vim_did_enter` variable is set, so that you can do:
--- ```vim
--- if v:vim_did_enter
---     call s:init()
--- else
---     au VimEnter * call s:init()
--- endif
--- ```
e.VimEnter = "VimEnter"

--- Before exiting Vim, just after writing the .shada file.
---
--- Executed only once, like VimLeavePre.
---
--- Use `v:dying` to detect an abnormal exit.
---
--- Use `v:exiting` to get the exit code.
---
--- Not triggered if `v:dying` is 2 or more.
e.VimLeave = "VimLeave"

--- Before exiting Vim, just before writing the .shada file.
---
--- This is executed only once, if there is a match with the name of what happens to be the current buffer when exiting.
---
--- Mostly useful with a "*" pattern:
---
--- ```vim
--- :autocmd VimLeavePre * call CleanupStuff()
--- ```
---
--- Use `v:dying` to detect an abnormal exit.
---
--- Use `v:exiting` to get the exit code.
---
--- Not triggered if `v:dying` is 2 or more.
e.VimLeavePre = "VimLeavePre"

--- After the Vim window was resized, thus 'lines' and/or 'columns' changed.
---
--- Not when starting up though.
e.VimResized = "VimResized"

--- After Nvim resumes from `suspend` state.
e.VimResume = "VimResume"

--- Before Nvim enters `suspend` state.
e.VimSuspend = "VimSuspend"

--- After closing a window.
---
--- The pattern is matched against the `window-ID`.
---
--- Both <amatch> and <afile> are set to the `window-ID`.
---
--- After WinLeave.
---
--- Non-recursive (event cannot trigger itself).
---
--- See also `ExitPre`, `QuitPre`.
e.WinClosed = "WinClosed"

--- After entering another window.
---
--- Not done for the first window, when Vim has just started.
---
--- Useful for setting the window height.
---
--- If the window is for another buffer, Vim executes the BufEnter autocommands after the WinEnter autocommands.
---
--- Note: For split and tabpage commands the WinEnter event is triggered after the split or tab command but before the file is loaded.
e.WinEnter = "WinEnter"

--- Before leaving a window.
---
--- If the window to be entered next is for a different buffer, Vim executes the BufLeave autocommands before the WinLeave autocommands (but not for ":new").
---
--- Not used for ":qa" or ":q" when exiting Vim.
---
--- Before WinClosed.
e.WinLeave = "WinLeave"

--- When a new window was created.
---
--- Not done for the first window, when Vim has just started.
---
--- Before WinEnter.
e.WinNew = "WinNew"

--- After scrolling the content of a window or resizing a window.
---
--- The pattern is matched against the `window-ID`.
---
--- Both <amatch> and <afile> are set to the `window-ID`.
---
--- Non-recursive (the event cannot trigger itself).
---
--- However, if the command causes the window to scroll or change size another WinScrolled event will be triggered later.
---
--- Does not trigger when the command is added, only after the first scroll or resize.
e.WinScrolled = "WinScrolled"


--- When lazy.nvim has finished starting up and loaded your config
e.LazyDone = "LazyDone"

--- After running sync
e.LazySync = "LazySync"

--- After an install
e.LazyInstall = "LazyInstall"

--- After an update
e.LazyUpdate = "LazyUpdate"

--- After a clean
e.LazyClean = "LazyClean"

--- After checking for updates
e.LazyCheck = "LazyCheck"

--- After running log
e.LazyLog = "LazyLog"

--- Triggered by change detection after reloading plugin specs
e.LazyReload = "LazyReload"

--- Triggered after `LazyDone` and processing `VimEnter` auto commands
e.VeryLazy = "VeryLazy"

--- Triggered after `UIEnter` when `require("lazy").stats().startuptime` has been calculated.
---
--- Useful to update the startuptime on your dashboard.
e.LazyVimStarted = "LazyVimStarted"

return e
