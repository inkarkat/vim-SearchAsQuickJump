" SearchAsQuickJump.vim: Quick search without affecting 'hlsearch', search pattern and history.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"   - ingo/regexp.vim autoload script
"   - SearchSpecial.vim autoload script
"   - SearchSpecial/CWord.vim autoload script

" Copyright: (C) 2009-2017 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   2.00.023	17-Nov-2017	Remove any search offset from the search
"				pattern; the underlying
"				SearchSpecial#SearchWithout() cannot directly
"				handle that.
"   1.00.022	31-Jan-2015	ENH: For Ex or debug command-line, also restore
"				the previous search pattern. This allows to
"				execute commands like :s without affecting the
"				current search.
"	021	24-May-2014	Move SearchSpecialCWord.vim to
"				SearchSpecial/CWord.vim.
"	020	28-Apr-2014	FIX: Need to expose s:OperatorPendingSearch().
"				FIX: Need to move s:NoHistoryMarkerLen.
"	019	26-Apr-2014	Split off autoload script.
"				Abort on error, as per the changed SearchSpecial
"				interface.
"	018	24-May-2013	Move ingosearch.vim to ingo-library.
"	017	24-May-2013	Move ingointegration#GetVisualSelection() into
"				ingo-library.
"	016	30-Sep-2011	Use <silent> for <Plug> mapping instead of
"				default mapping.
"	015	12-Sep-2011	Use ingointegration#GetVisualSelection() instead
"				of inline capture.
"	014	17-May-2011	Also save and restore regtype of the unnamed
"				register in mappings.
"				Also avoid clobbering the selection and
"				clipboard registers.
"	013	19-May-2010	Now also works with operator-pending searches
"				(e.g. d/foo<S-CR>) by hooking into ":omap /" and
"				adding a special case for it.
"	012	19-May-2010	Do not activate the quick search for |n| / |N|
"				commands (if the SearchRepeat plugin is
"				installed). It is typically not desired to
"				modify the last pattern by quick searches, and
"				one can explicitly repeat a quick search via the
"				|goq| / |goQ| mappings, anyway.
"	011	05-Jan-2010	Moved SearchHighlighting#GetSearchPattern() into
"				separate ingosearch.vim utility module and
"				renamed to
"				ingosearch#LiteralTextToSearchPattern().
"	010	08-Oct-2009	Make definition of star commands optional via
"				g:SearchAsQuickJump_DefineStarCommands; I do not
"				use them, and the default 'q' prefix clashes
"				with many buffer-local "quit" mappings.
"	009	06-Oct-2009	Do not define q* and q# mappings for select
"				mode; printable characters should start insert
"				mode.
"	008	05-Oct-2009	UNDO: Replaced <C-CR> with <S-CR>.
"	007	10-Sep-2009	Replaced <S-CR> with <C-CR>, which is slightly
"				easier to reach when Ctrl is mapped to the Caps
"				Lock key.
"				BUG: Must remove history marker when not in a
"				search.
"	006	17-Aug-2009	Added a:description to SearchRepeat#Register().
"	005	17-Jul-2009	Adapted to changed interface of
"				SearchSpecial#SearchWithout: Passing in
"				l:cwordStartPosition in a dictionary.
"				Now defaulting to empty list instead of [0, 0]
"				for no currentMatchPosition; it's slightly more
"				efficient.
"				The SearchSpecial#SearchWithout() function now
"				supports the 'isStarSearch' option, so removed
"				temporary disabling of 'smartcase' here.
"	004	14-Jul-2009	Now handling optional [count] with the aid of
"				the SearchRepeat plugin.
"				The "Star" and "Hash" mappings do not use the
"				'smartcase' setting any more, like the built-in
"				* and # commands on which they are based. To
"				maintain a single "quick search" integration
"				into SearchRepeat, the search type (/ vs. *) is
"				stored in the s:isStarSearch flag, so that a
"				single set of <Plug>SearchAsQuickJumpNext
"				mappings can be registered and used for both
"				searches using / not using 'smartcase'.
"	003	12-Jul-2009	Added parallel mappings for the '*' and '#'
"				commands in normal mode.
"				BF: Backward search from inside the current word
"				jumped to the beginning of the current word, not
"				the previous match. Enhanced
"				SearchSpecial#SearchWithout() function to take
"				an optional l:cwordStartPosition and skip this
"				during backward searches.
"				Enhanced SearchSpecial#SearchWithout() function
"				now allows to pass in empty predicate, removing
"				the need for a dummy "always true" predicate.
"	002	11-Jul-2009	First working version.
"	001	10-Jul-2009	file creation

"- use of SearchSpecial library -----------------------------------------------

function! SearchAsQuickJump#DoSearch( count, isBackward, ... )
    return SearchSpecial#SearchWithout(s:quickSearchPattern, a:isBackward, '', 'quick', '', a:count, {'additionalSearchFlags': 'e', 'isStarSearch': s:isStarSearch, 'currentMatchPosition': (a:0 ? a:1 : [])})
endfunction


"- other functions ------------------------------------------------------------

let s:isOperatorPendingSearch = 0
function! SearchAsQuickJump#OperatorPendingSearch( searchOperator )
    " We set a simple flag to indicate to SearchAsQuickJump#QuickSearch() that
    " an operator is pending for the current search.
    let s:isOperatorPendingSearch = 1

    " If an operator-pending search is canceled or concluded with the default
    " <CR>, SearchAsQuickJump#QuickSearch cannot clear the flag. We would need
    " to hook into <Esc>, <CR>, etc. in command-line mode to be notified of
    " this. Instead, we set up a temporary, one-shot autocmd to clear the flag
    " on the next occasion. Mostly, this should be the CursorMoved event, which
    " fortunately isn't fired when 'incsearch' highlights the potential match,
    " only when the operator results in a cursor move. The other events are only
    " there to be safe.
    augroup SearchAsQuickJumpOperatorPendingSearchOff
	autocmd! BufLeave,WinLeave,InsertEnter,CursorHold,CursorMoved * let s:isOperatorPendingSearch = 0 | autocmd! SearchAsQuickJumpOperatorPendingSearchOff
    augroup END

    return a:searchOperator
endfunction

function! s:SearchText( text, count, isWholeWordSearch, isBackward, cwordStartPosition )
    let s:isStarSearch = 1
    let s:quickSearchPattern = ingo#regexp#FromLiteralText(a:text, a:isWholeWordSearch, '')
    let s:quickSearchOffset = ''
    return SearchAsQuickJump#DoSearch(a:count, a:isBackward, a:cwordStartPosition)
endfunction
function! SearchAsQuickJump#SearchCWord( isWholeWordSearch, isBackward )
    let l:cwordStartPosition = (a:isBackward ? SearchSpecial#CWord#GetStartPosition(s:quickSearchPattern) : [])
    return s:SearchText(expand('<cword>'), v:count1, a:isWholeWordSearch, a:isBackward, l:cwordStartPosition)
endfunction
function! SearchAsQuickJump#SearchSelection( text, count, isWholeWordSearch, isBackward )
    return s:SearchText(a:text, a:count, a:isWholeWordSearch, a:isBackward, [])
endfunction
function! SearchAsQuickJump#JumpAfterSearchCommand( isBackward )
    call histdel('search', -1)

    " If the SearchRepeat plugin is installed, it provides the [count] given to
    " the last search command for other consumers. Otherwise, we do not support
    " [count], as that would mean remapping the / and ? commands just to record
    " the [count].
    let l:count = ((exists('g:lastSearchCount') && g:lastSearchCount) ? g:lastSearchCount : 1)

    return SearchAsQuickJump#DoSearch(l:count, a:isBackward)
endfunction
let s:previousSearchPattern = ''
function! SearchAsQuickJump#RestorePreviousSearch()
    if @/ !=# s:previousSearchPattern
	if @/ ==# histget('search', -1)
	    call histdel('search', -1)
	endif
	let @/ = s:previousSearchPattern
    endif
endfunction

let s:NoHistoryMarkerLen = 3
function! SearchAsQuickJump#QuickSearch()
    let l:cmdtype= getcmdtype()
    if l:cmdtype ==# '/'
	let l:isBackward = 0
    elseif l:cmdtype ==# '?'
	let l:isBackward = 1
    elseif l:cmdtype =~# '[:>]'
	" Remove the history marker and conclude the command line with a normal
	" <Enter>. Then, restore the current search pattern if the executed
	" command (e.g. :s) has changed it.
	let s:previousSearchPattern = @/
	return repeat("\<BS>", s:NoHistoryMarkerLen) . "\<CR>:call SearchAsQuickJump#RestorePreviousSearch()\<CR>"
    else
	" Remove the history marker and conclude the command line with a normal
	" <Enter>.
	return repeat("\<BS>", s:NoHistoryMarkerLen) . "\<CR>"
    endif

    let s:isStarSearch = 0
    let l:quickSearch = strpart(getcmdline(), 0, strlen(getcmdline()) - s:NoHistoryMarkerLen)
    if l:cmdtype =~# '^[/?]$'
	let [s:quickSearchPattern, s:quickSearchOffset] = matchlist(l:quickSearch, '^\(.\{-}\)\%(\%(\%(^\|[^\\]\)\%(\\\\\)*\\\)\@<!' . l:cmdtype . '\(.*\)\)\?$')[1:2]
    else
	let [s:quickSearchPattern, s:quickSearchOffset] = [l:quickSearch, '']
    endif

    if s:isOperatorPendingSearch
	let s:isOperatorPendingSearch = 0
	" If this search is part of an operator (e.g. "d/foo<S-CR>"), we have to
	" execute the search, so that the operator applies; canceling and
	" jumping to the match won't do. (Canceling and re-executing via
	" :execute v:operator . '/' . s:quickSearchPattern . "\<CR>" will still
	" clobber the search history, we would have to write our own motion or
	" at least come up with a visual selection up to the match.)
	" Fortunately, we don't have to worry about what happens after the
	" operator, and can happily append commands to remove the search pattern
	" from the history.
"****D echomsg '**** operator at' string(getpos('.'))
	return repeat("\<BS>", s:NoHistoryMarkerLen) . "\<CR>:call histdel('search', -1)|let @/ = histget('search', -1)\<CR>"
    else
	" Note: Must use CTRL-C to abort search command-line; <Esc> somehow doesn't
	" work.
	return "\<C-c>:if ! SearchAsQuickJump#JumpAfterSearchCommand(" . l:isBackward . ") | echoerr ingo#err#Get() | endif\<CR>"
    endif
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
