--" Vim ftplugin for PO file (GNU gettext) editing.
--" Maintainer:	Aleksandar Jelenak <ajelenak AT yahoo.com>
--" Last Change:	Tue, 12 Apr 2005 13:49:55 -0400
--"
--" *** Latest version: http://www.vim.org/scripts/script.php?script_id=695 ***
--"
--" DESCRIPTION
--"     This file is a Vim ftplugin for editing PO files (GNU gettext -- the GNU
--"     i18n and l10n system). It automates over a dozen frequent tasks that
--"     occur while editing files of this type.
--"
--"                                                      Key mappings
--"     Action (Insert mode)                            GUI Vim     Vim
--"     ===============================================================
--"     Move to an untransl. string forward             <S-F1>      \m
--"     Move to an untransl. string backward            <S-F2>      \p
--"     Copy the msgid string to msgstr                 <S-F3>      \c
--"     Delete the msgstr string                        <S-F4>      \d
--"     Move to the next fuzzy translation              <S-F5>      \f
--"     Move to the previous fuzzy translation          <S-F6>      \b
--"     Label the translation fuzzy                     <S-F7>      \z
--"     Remove the fuzzy label                          <S-F8>      \r
--"     Show msgfmt statistics for the file(*)          <S-F11>     \s
--"     Browse through msgfmt errors for the file(*)    <S-F12>     \e
--"     Put the translator info in the header           \t          \t
--"     Put the lang. team info in the header           \l          \l
--"     ---------------------------------------------------------------
--"     (*) Only available on UNIX computers.
--"
--"
--"                                                      Key mappings
--"     Action (Normal mode)                            GUI Vim     Vim
--"     ===============================================================
--"     Move to an untransl. string forward             <S-F1>      \m
--"     Move to an untransl. string backward            <S-F2>      \p
--"     Move to the next fuzzy translation              <S-F5>      \f
--"     Move to the previous fuzzy translation          <S-F6>      \b
--"     Label the translation fuzzy                     <S-F7>      \z
--"     Remove the fuzzy label                          <S-F8>      \r
--"     Split-open the file under cursor                  gf        gf
--"     Show msgfmt statistics for the file(*)          <S-F11>     \s
--"     Browse through msgfmt errors for the file(*)    <S-F12>     \e
--"     Put the translator info in the header           \t          \t
--"     Put the lang. team info in the header           \l          \l
--"     ---------------------------------------------------------------
--"     (*) Only available on UNIX computers.
--"
--"     Remarks:
--"     - "S" in the above key mappings stands for the <Shift> key and "\" in
--"       fact means "<LocalLeader>" (:help <LocalLeader>), which is "\" by
--"       Vim's default.
--"     - Information about the translator and language team is supplied by two
--"       global variables: 'g:po_translator' and 'g:po_lang_team'. They should
--"       be defined in the ".vimrc" (UNIX) or "_vimrc" (Windows) file. If they
--"       are not defined, the default values (descriptive strings) are put
--"       instead.
--"     - Vim's "gf" Normal mode command is remapped (local to the PO buffer, of
--"       course). It will only function on lines starting with "#: ". Search
--"       for the file is performed in the directories specified by the 'path'
--"       option. The user can supply its own addition to this option via the
--"       'g:po_path' global variable. Its default value for PO files can be
--"       found by typing ":set path?" from within a PO buffer. For the correct
--"       format please see ":help 'path'". Warning messages are printed if no
--"       or more than one file is found.
--"     - Vim's Quickfix mode (see ":help quickfix") is used for browsing
--"       through msgfmt-reported errors for the file. No MO file is created
--"       when running the msgfmt program since its output is directed to
--"       "/dev/null". The user can supply command-line arguments to the msgfmt
--"       program via the global variable 'g:po_msgfmt_args'. All arguments are
--"       allowed except the "-o" for output file. The default value is
--"       "-vv?-c".
--"
--"     But there's even more!
--"
--"     Every time the PO file is saved, a PO-formatted time stamp is
--"     automatically added to the file header.
--"
--" INSTALLATION
--"     Put this file in a Vim ftplugin directory. On UNIX computers it is
--"     usually either "~/.vim/ftplugin" or "~/.vim/after/ftplugin". On Windows
--"     computers, the defaults are "$VIM\vimfiles\ftplugin" or
--"     "$VIM\vimfiles\after\ftplugin". For more information consult the Vim
--"     help, ":help 'ftplugin'" and ":help 'runtimepath'".
--"
--" REMOVAL
--"     Just delete the bloody file!
-- Only do this when not done yet for this buffer.
if vim.b.did_po_mode_ftplugin then
	return
end
vim.b.did_po_mode_ftplugin = 1

--if exists("b:did_po_mode_ftplugin")
--   finish
--endif
--let b:did_po_mode_ftplugin = 1
--
--setlocal comments=
--setlocal errorformat=%f:%l:\ %m
--setlocal makeprg=msgfmt
--
--let b:po_path = '.,..,../src,../src/*'
--if exists("g:po_path")
--   let b:po_path = b:po_path . ',' . g:po_path
--endif
--exe "setlocal path=" . b:po_path
--unlet b:po_path
--
----" Check if GUI Vim is running.
--if has("gui_running")
--   let gui = 1
--else
--   let gui = 0
--endif

local M = {}
local api = vim.api

local NextUntranslatedFwd = function()
	local re_NextUntranslatedFwd = vim.regex([[^msgstr\s*""(\n\n\\|\%$\)]])
	local re_EmtyLine = vim.regex([[(^\s*$|\%$)]])
	local line = api.nvim_win_get_cursor(0)[1]
	local lastline = vim.fn.line("$")

	while line < lastline do
		if re_NextUntranslatedFwd:match_line(0, line) then
			print("Gefunden: " .. line)
			if re_EmtyLine:match_line(0, line + 1) then
				api.nvim_win_set_cursor(0, { line, 0 })
				vim.cmd("zt") -- top this line
				break
			end
		else
			line = line + 1
		end
	end
end -- NextUntranslatedFwd

-- in lua/whid.lua

-- Edit translation in floating window
local buf, win

local function open_window(msgstr)
	buf = api.nvim_create_buf(false, true) -- create new emtpy buffer

	api.nvim_buf_set_option(buf, "bufhidden", "wipe")

	api.nvim_buf_set_lines(buf, 0, 0, false, msgstr)

	-- get dimensions
	local max_width = api.nvim_get_option("columns")
	local max_height = api.nvim_get_option("lines")

	-- calculate our floating window size
	local win_height = math.ceil(height * 0.8 - 4)
	local win_width = math.ceil(width * 0.8)

	-- and its starting position
	local row = math.ceil((height - win_height) / 2 - 1)
	local col = math.ceil((width - win_width) / 2)

	-- set some options
	local opts = {
		style = "minimal",
		relative = "editor",
		width = win_width,
		height = win_height,
		row = row,
		col = col,
	}
	-- and finally create it with buffer attached
	win = api.nvim_open_win(buf, true, opts)
end

-- api.nvim_get_current_line() get current line
-- vim.regex() --regex object

M.setup = function()
	--
	----" Move to the first untranslated msgstr string forward.
	--inoremap <buffer> <unique> <Plug>NextTransFwd <ESC>/^msgstr\s*""\(\n\n\\|\%$\)<CR>:let @/=""<CR>:call histdel("/", -1)<CR>z.f"a
	vim.keymap.set(
		"i",
		"<Leader>pn",
		-- sucht nach msgstr
		-- let @/="" leere letzes Suchregister
		-- z. Zentriere aktuelle Zeile in BS Mitte
		-- f - gehe nach rechts,  "a register a????"
		-- [[<ESC>/^msgstr\s*""\(\n\n\\|\%$\)<CR>:let @/=""<CR>:call histdel("/", -1)<CR>z.f"a]],
		NextUntranslatedFwd,
		{ buffer = true, desc = "Next untranslated entry" }
	)
	--nnoremap <buffer> <unique> <Plug>NextTransFwd /^msgstr\s*""\(\n\n\\|\%$\)<CR>:let @/=""<CR>:call histdel("/", -1)<CR><C-L>z.
	vim.keymap.set(
		"n",
		"<Leader>pn",
		[[/^msgstr\s*""\(\n\n\\|\%$\)<CR>:let @/=""<CR>:call histdel("/", -1)<CR><C-L>z.]],
		{ buffer = true, desc = "Next untranslated entry" }
	)

	--" Move to the first untranslated msgstr string backward.
	--inoremap <buffer> <unique> <Plug>NextTransBwd <ESC>{?^msgstr\s*""\(\n\n\\|\%$\)<CR>:let @/=""<CR>:call histdel("/", -1)<CR>z.f"a
	vim.keymap.set(
		"i",
		"<Leader>pr",
		[[<ESC>{?^msgstr\s*""\(\n\n\\|\%$\)<CR>:let @/=""<CR>:call histdel("/", -1)<CR>z.f"a]],
		{ buffer = true, desc = "Previous untranslated entry" }
	)
	--nnoremap <buffer> <unique> <Plug>NextTransBwd {?^msgstr\s*""\(\n\n\\|\%$\)<CR>:let @/=""<CR>:call histdel("/", -1)<CR><C-L>z.
	vim.keymap.set(
		"n",
		"<Leader>pr",
		[[{?^msgstr\s*""\(\n\n\\|\%$\)<CR>:let @/=""<CR>:call histdel("/", -1)<CR><C-L>z.]],
		{ buffer = true, desc = "Previous untranslated entry" }
	)

	-- Copy original msgid string into msgstr string.
	--if !hasmapto('<Plug>CopyMsgid')
	--   if gui
	--      imap <buffer> <unique> <S-F3> <Plug>CopyMsgid
	--   else
	--      imap <buffer> <unique> <LocalLeader>c <Plug>CopyMsgid
	--   endif
	--endif
	--inoremap <buffer> <unique> <Plug>CopyMsgid <ESC>}?^msgid<CR>:let @/=""<CR>:call histdel("/", -1)<CR>f"y/^msgstr<CR>/^msgstr<CR>:let @/=""<CR>:call histdel("/", -1)<CR>f""_d$pa
	vim.keymap.set(
		"i",
		"<LocalLeader>c",
		[[<ESC>}?^msgid<CR>:let @/=""<CR>:call histdel("/", -1)<CR>f"y/^msgstr<CR>/^msgstr<CR>:let @/=""<CR>:call histdel("/", -1)<CR>f""_d$pa]],
		{ buffer = true, desc = "Copy original msgid to msgstr" }
	)
	vim.keymap.set(
		"n",
		"<LocalLeader>c",
		[[}?^msgid<CR>:let @/=""<CR>:call histdel("/", -1)<CR>f"y/^msgstr<CR>/^msgstr<CR>:let @/=""<CR>:call histdel("/", -1)<CR>f""_d$pa]],
		{ buffer = true, desc = "Copy original msgid to msgstr" }
	)
	--
	---- Erase the translation string.
	--if !hasmapto('<Plug>DeleteTrans')
	--   if gui
	--      imap <buffer> <unique> <S-F4> <Plug>DeleteTrans
	--   else
	--      imap <buffer> <unique> <LocalLeader>d <Plug>DeleteTrans
	--   endif
	--endif
	--inoremap <buffer> <unique> <Plug>DeleteTrans <ESC>}?^msgstr<CR>:let @/=""<CR>:call histdel("/", -1)<CR>f"lc}"<ESC>i
	vim.keymap.set(
		"i",
		"<LocalLeader>d",
		[[<ESC>}?^msgstr<CR>:let @/=""<CR>:call histdel("/", -1)<CR>f"lc}"<ESC>i]],
		{ buffer = true, desc = "Erase translated string" }
	)
	--
	----" Move to the first fuzzy translation forward.
	--if !hasmapto('<Plug>NextFuzzy')
	--   if gui
	--      imap <buffer> <unique> <S-F5> <Plug>NextFuzzy
	--      nmap <buffer> <unique> <S-F5> <Plug>NextFuzzy
	--   else
	--      imap <buffer> <unique> <LocalLeader>f <Plug>NextFuzzy
	--      nmap <buffer> <unique> <LocalLeader>f <Plug>NextFuzzy
	--   endif
	--endif
	--inoremap <buffer> <unique> <Plug>NextFuzzy <ESC>/^#,\(.*,\)\=\s*fuzzy<CR>:let @/=""<CR>:call histdel("/", -1)<CR>/^msgstr<CR>:let @/=""<CR>:call histdel("/", -1)<CR>z.$i
	--nnoremap <buffer> <unique> <Plug>NextFuzzy /^#,\(.*,\)\=\s*fuzzy<CR>:let @/=""<CR>:call histdel("/", -1)<CR>/^msgstr<CR>:let @/=""<CR>:call histdel("/", -1)<CR><C-L>z.$
	vim.keymap.set(
		"i",
		"<LocalLeader>f",
		[[<ESC>/^#,\(.*,\)\=\s*fuzzy<CR>:let @/=""<CR>:call histdel("/", -1)<CR>/^msgstr<CR>:let @/=""<CR>:call histdel("/", -1)<CR>z.$i]],
		{ buffer = true, desc = "Move to next fuzzy entry" }
	)
	vim.keymap.set(
		"n",
		"<LocalLeader>f",
		[[/^#,\(.*,\)\=\s*fuzzy<CR>:let @/=""<CR>:call histdel("/", -1)<CR>/^msgstr<CR>:let @/=""<CR>:call histdel("/", -1)<CR><C-L>z.$]],
		{ buffer = true, desc = "Move to next fuzzy entry" }
	)

	----" Move to the first fuzzy descriptor backward.
	--if !hasmapto('<Plug>PreviousFuzzy')
	--   if gui
	--      imap <buffer> <unique> <S-F6> <Plug>PreviousFuzzy
	--      nmap <buffer> <unique> <S-F6> <Plug>PreviousFuzzy
	--   else
	--      imap <buffer> <unique> <LocalLeader>b <Plug>PreviousFuzzy
	--      nmap <buffer> <unique> <LocalLeader>b <Plug>PreviousFuzzy
	--   endif
	--endif
	--inoremap <buffer> <unique> <Plug>PreviousFuzzy <ESC>{?^#,\(.*,\)\=\s*fuzzy<CR>:let @/=""<CR>:call histdel("/", -1)<CR>/^msgstr<CR>:let @/=""<CR>:call histdel("/", -1)<CR>z.$i
	--nnoremap <buffer> <unique> <Plug>PreviousFuzzy {?^#,\(.*,\)\=\s*fuzzy<CR>:let @/=""<CR>:call histdel("/", -1)<CR>/^msgstr<CR>:let @/=""<CR>:call histdel("/", -1)<CR><C-L>z.$
	vim.keymap.set(
		"i",
		"<LocalLeader>b",
		[[<ESC>{?^#,\(.*,\)\=\s*fuzzy<CR>:let @/=""<CR>:call histdel("/", -1)<CR>/^msgstr<CR>:let @/=""<CR>:call histdel("/", -1)<CR>z.$i]],
		{ buffer = true, desc = "Move to previous fuzzy entry" }
	)
	vim.keymap.set(
		"n",
		"<LocalLeader>b",
		[[{?^#,\(.*,\)\=\s*fuzzy<CR>:let @/=""<CR>:call histdel("/", -1)<CR>/^msgstr<CR>:let @/=""<CR>:call histdel("/", -1)<CR><C-L>z.$]],
		{ buffer = true, desc = "Move to previous fuzzy entry" }
	)

	----" Insert fuzzy description for the translation.
	--if !hasmapto('<Plug>InsertFuzzy')
	--   if gui
	--      imap <buffer> <unique> <S-F7> <Plug>InsertFuzzy
	--      nmap <buffer> <unique> <S-F7> <Plug>InsertFuzzy
	--   else
	--      imap <buffer> <unique> <LocalLeader>z <Plug>InsertFuzzy
	--      nmap <buffer> <unique> <LocalLeader>z <Plug>InsertFuzzy
	--   endif
	--endif
	--inoremap <buffer> <unique> <Plug>InsertFuzzy <ESC>{vap:call <SID>InsertFuzzy()<CR>gv<ESC>}i
	--nnoremap <buffer> <unique> <Plug>InsertFuzzy {vap:call <SID>InsertFuzzy()<CR>gv<ESC>}

	vim.cmd([[
function! InsertFuzzy() range
   let n = a:firstline
   while n <= a:lastline
      let line = getline(n)
      if line =~ '^#,.*fuzzy'
         return
      elseif line =~ '^#,'
         call setline(n, substitute(line, '#,','#, fuzzy,', ""))
         return
      elseif line =~ '^msgid'
         call append(n-1, '#, fuzzy')
         return
      endif
      let n = n + 1
   endwhile
endf
]])

	-- TODO insert mode
	vim.keymap.set("n", "<LocalLeader>z", function()
		vim.fn.InsertFuzzy()
	end, { buffer = true, desc = "Insert Fuzzy mark" })
	--
	----" Remove fuzzy description from the translation.
	--if !hasmapto('<Plug>RemoveFuzzy')
	--   if gui
	--      imap <buffer> <unique> <S-F8> <Plug>RemoveFuzzy
	--      nmap <buffer> <unique> <S-F8> <Plug>RemoveFuzzy
	--   else
	--      imap <buffer> <unique> <LocalLeader>r <Plug>RemoveFuzzy
	--      nmap <buffer> <unique> <LocalLeader>r <Plug>RemoveFuzzy
	--   endif
	--endif
	--inoremap <buffer> <unique> <Plug>RemoveFuzzy <ESC>{vap:call <SID>RemoveFuzzy()<CR>i
	--nnoremap <buffer> <unique> <Plug>RemoveFuzzy {vap:call <SID>RemoveFuzzy()<CR>

	vim.cmd([[
function! RemoveFuzzy()
let line = getline(".")
if line =~ '^#,\s*fuzzy$'
exe "normal! dd"
elseif line =~ '^#,\(.*,\)\=\s*fuzzy'
exe 's/,\s*fuzzy//'
endif
endf
]])

	-- TODO insert mode
	vim.keymap.set("n", "<LocalLeader>r", function()
		vim.fn.RemoveFuzzy()
	end, { buffer = true, desc = "Remove Fuzzy mark" })
	--
	----" Show PO translation statistics. (Only available on UNIX computers for now.)
	--if has("unix")
	--   if !hasmapto('<Plug>MsgfmtStats')
	--      if gui
	--         imap <buffer> <unique> <S-F11> <Plug>MsgfmtStats
	--         nmap <buffer> <unique> <S-F11> <Plug>MsgfmtStats
	--      else
	--         imap <buffer> <unique> <LocalLeader>s <Plug>MsgfmtStats
	--         nmap <buffer> <unique> <LocalLeader>s <Plug>MsgfmtStats
	--      endif
	--   endif
	--   inoremap <buffer> <unique> <Plug>MsgfmtStats <ESC>:call <SID>Msgfmt('stats')<CR>
	--   nnoremap <buffer> <unique> <Plug>MsgfmtStats :call <SID>Msgfmt('stats')<CR>
	--
	--   if !hasmapto('<Plug>MsgfmtTest')
	--      if gui
	--         imap <buffer> <unique> <S-F12> <Plug>MsgfmtTest
	--         nmap <buffer> <unique> <S-F12> <Plug>MsgfmtTest
	--      else
	--         imap <buffer> <unique> <LocalLeader>e <Plug>MsgfmtTest
	--         nmap <buffer> <unique> <LocalLeader>e <Plug>MsgfmtTest
	--      endif
	--   endif
	--   inoremap <buffer> <unique> <Plug>MsgfmtTest <ESC>:call <SID>Msgfmt('test')<CR>
	--   nnoremap <buffer> <unique> <Plug>MsgfmtTest :call <SID>Msgfmt('test')<CR>

	local function Msgfmt(action)
		vim.b.comments = ""
		vim.b.errorformat = [[%f:%l:\ %m]]
		vim.b.makeprg = "msgfmt"
		--local api = vim.api
		--local current_line =  api.nvim_get_current_line()

		-- save the file first
		vim.cmd([[if &modified | w | endif]])
		--api.nvim_set_current_line('1')

		if action == "stats" then
			vim.cmd([[!msgfmt --statistics -o /dev/null %]])
		elseif action == "test" then
			vim.cmd([[make! -vv -c -o /dev/null %]])
		end

		vim.cmd("copen") -- open quickfix window
	end

	vim.keymap.set("n", "<LocalLeader>s", function()
		Msgfmt("stats")
	end, { buffer = true, desc = "Print statistics" })

	vim.keymap.set("n", "<LocalLeader>e", function()
		Msgfmt("test")
	end, { buffer = true, desc = "Browse Errors" })

	--   function! <SID>Msgfmt(action)
	--      " Check if the file needs to be saved first.
	--      execute "if &modified | w | endif"
	--      if a:action == 'stats'
	--         execute "!msgfmt --statistics -o /dev/null %"
	--      elseif a:action == 'test'
	--         if exists("g:po_msgfmt_args")
	--            let args = g:po_msgfmt_args
	--         else
	--            let args = '-vv -c'
	--         endif
	--         execute "make! " . args . " -o /dev/null %"
	--         " open quickfix window
	--         copen
	--      endif
	--   endfunction
	-- endif "has unix
	--
	----" Add translator info in the file header.
	--if !hasmapto('<Plug>TranslatorInfo')
	--   if gui
	--      imap <buffer> <unique> <LocalLeader>t <Plug>TranslatorInfo
	--      nmap <buffer> <unique> <LocalLeader>t <Plug>TranslatorInfo
	--   else
	--      imap <buffer> <unique> <LocalLeader>t <Plug>TranslatorInfo
	--      nmap <buffer> <unique> <LocalLeader>t <Plug>TranslatorInfo
	--   endif
	--endif
	--inoremap <buffer> <unique> <Plug>TranslatorInfo <ESC>:call <SID>AddHeaderInfo('person')<CR>i
	--nnoremap <buffer> <unique> <Plug>TranslatorInfo :call <SID>AddHeaderInfo('person')<CR>
	--
	---- Add language team info in the file header.
	--if !hasmapto('<Plug>LangTeamInfo')
	--   if gui
	--      imap <buffer> <unique> <LocalLeader>l <Plug>LangTeamInfo
	--      nmap <buffer> <unique> <LocalLeader>l <Plug>LangTeamInfo
	--   else
	--      imap <buffer> <unique> <LocalLeader>l <Plug>LangTeamInfo
	--      nmap <buffer> <unique> <LocalLeader>l <Plug>LangTeamInfo
	--   endif
	--endif
	--inoremap <buffer> <unique> <Plug>LangTeamInfo <ESC>:call <SID>AddHeaderInfo('team')<CR>i
	--nnoremap <buffer> <unique> <Plug>LangTeamInfo :call <SID>AddHeaderInfo('team')<CR>
	--
	--fu! <SID>AddHeaderInfo(action)
	--   if a:action == 'person'
	--      let search_for = 'Last-Translator'
	--      if exists("g:po_translator")
	--         let add = g:po_translator
	--      else
	--         let add = 'YOUR NAME <E-MAIL@ADDRESS>'
	--      endif
	--   elseif a:action == 'team'
	--      let search_for = 'Language-Team'
	--      if exists("g:po_lang_team")
	--         let add = g:po_lang_team
	--      else
	--         let add = 'LANGUAGE TEAM <E-MAIL@ADDRESS or HOME PAGE>'
	--      endif
	--   else
	--      " Undefined action -- just do nothing.
	--      return
	--   endif
	--   let search_for = '"' . search_for . ':'
	--   let add = add . '\\n"'
	--
	--   normal! 1G
	--   if search('^' . search_for)
	--      silent! exe 's/^\(' . search_for . '\).*$/\1 ' . add
	--   endif
	--   call histdel("/", -1)
	--endf
	--
	---- Write automagically PO-formatted time stamp every time the file is saved.
	--augroup PoFileTimestamp
	--   au!zeit
	--   au BufWrite *.po,*.po.gz call <SID>PoFileTimestamp()
	--augroup END

	vim.api.nvim_create_autocmd("BufWrite", {
		pattern = "*.po,*.po.gz",
		--group = "PoFileTimestamp",
		command = [[
  " Prepare for cleanup at the end of this function.
  let hist_search = histnr("/")
  let old_report = 'set report='.&report
  let &report = 100
  let cursor_pos_cmd = line(".").'normal! '.virtcol(".").'|'
  normal! H
  let scrn_pos = line(".").'normal! zt'

  " Put in time stamp.
  normal! 1G
  if search('^"PO-Revision-Date:')
     silent! exe 's/^\("PO-Revision-Date:\).*$/\1 ' . strftime("%Y-%m-%d %H:%M%z") . '\\n"'
  endif

  " Cleanup and restore old cursor position.
  while histnr("/") > hist_search && histnr("/") > 0
     call histdel("/", -1)
  endwhile
  exe scrn_pos
  exe cursor_pos_cmd
  exe old_report
  ]],
	})

	--fu! <SID>PoFileTimestamp()
	--   " Prepare for cleanup at the end of this function.
	--   let hist_search = histnr("/")
	--   let old_report = 'set report='.&report
	--   let &report = 100
	--   let cursor_pos_cmd = line(".").'normal! '.virtcol(".").'|'
	--   normal! H
	--   let scrn_pos = line(".").'normal! zt'
	--
	--   --" Put in time stamp.
	--   normal! 1G
	--   if search('^"PO-Revision-Date:')
	--      silent! exe 's/^\("PO-Revision-Date:\).*$/\1 ' . strftime("%Y-%m-%d %H:%M%z") . '\\n"'
	--   endif
	--
	--   --" Cleanup and restore old cursor position.
	--   while histnr("/") > hist_search && histnr("/") > 0
	--      call histdel("/", -1)
	--   endwhile
	--   exe scrn_pos
	--   exe cursor_pos_cmd
	--   exe old_report
	--endf
	--
	----" On "gf" Normal mode command, split window and open the file under the cursor.
	--if !hasmapto('<Plug>OpenSourceFile')
	--   map <buffer> <unique> gf <Plug>OpenSourceFile
	--endif
	--noremap <buffer> <unique> <Plug>OpenSourceFile :call <SID>OpenSourceFile()<CR>
	--
	----" This opens the file under the cursor in a split-window.
	--fu! <SID>OpenSourceFile()
	--   --" Check if we're at the right line. Return if not.
	--   if getline(".") !~ '^#:\s\+' | return | endif
	--
	--   --" Get the reference, check it, and return if it doesn't have the assumed format.
	--   let ref = expand("<cWORD>")
	--   if ref !~ ':\d\+$' | return | endif
	--
	--   --" Split the reference into the file name and the line number parts.
	--   let d = match(ref, ':')
	--   let flnm = strpart(ref, 0, d)
	--   let lnr = strpart(ref, d+1, 100)
	--
	--   --" Start searching for the file in the directories specified with the 'path'
	--   " option.
	--   let ff = globpath(&path, flnm)
	--
	--   --" Check what's been found. Report if no or more than one file found and return.
	--   if ff == ''
	--      echohl WarningMsg | echo "No file found in the path."
	--      echohl None
	--      exe "normal \<Esc>"
	--   elseif match(ff, "\n") > 0
	--      echohl WarningMsg | echo "More than one file found: " . ff . "\nAborting."
	--      echohl None
	--      exe "normal \<Esc>"
	--   else
	--      " Split the window and open the file at the correct line.
	--      execute "silent sp +" . lnr . " " . ff
	--   endif
	--endf
	--
	--unlet gui
end --setup

return M
