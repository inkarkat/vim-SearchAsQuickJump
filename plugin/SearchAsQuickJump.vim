" SearchAsQuickJump.vim: Quick search without affecting 'hlsearch', search pattern and history.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"   - ingo/regexp.vim autoload script
"   - ingo/selection.vim autoload script
"   - SearchSpecial.vim autoload script
"   - SearchSpecialCWord.vim autoload script
"   - SearchRepeat.vim autoload script (optional integration)

" Copyright: (C) 2009-2014 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
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

" Avoid installing twice or when in unsupported Vim version.
if exists('g:loaded_SearchAsQuickJump') || (v:version < 700)
    finish
endif
let g:loaded_SearchAsQuickJump = 1

"- configuration --------------------------------------------------------------

if ! exists('g:SearchAsQuickJump_DefineStarCommands')
    let g:SearchAsQuickJump_DefineStarCommands = 0
endif


"- use of SearchSpecial library -----------------------------------------------

function! s:DoSearch( count, isBackward, ... )
    return SearchSpecial#SearchWithout(s:quickSearchPattern, a:isBackward, '', 'quick', '', a:count, {'isStarSearch': s:isStarSearch, 'currentMatchPosition': (a:0 ? a:1 : [])})
endfunction
nnoremap <silent> <Plug>SearchAsQuickJumpNext :<C-u>if ! <SID>DoSearch(v:count1, 0)<Bar>echoerr ingo#err#Get()<Bar>endif
nnoremap <silent> <Plug>SearchAsQuickJumpPrev :<C-u>if ! <SID>DoSearch(v:count1, 1)<Bar>echoerr ingo#err#Get()<Bar>endif


"- functions ------------------------------------------------------------------

let s:isOperatorPendingSearch = 0
function! s:OperatorPendingSearch( searchOperator )
    " We set a simple flag to indicate to s:QuickSearch() that an operator is
    " pending for the current search.
    let s:isOperatorPendingSearch = 1

    " If an operator-pending search is canceled or concluded with the default
    " <CR>, s:QuickSearch cannot clear the flag. We would need to hook into
    " <Esc>, <CR>, etc. in command-line mode to be notified of this. Instead, we
    " set up a temporary, one-shot autocmd to clear the flag on the next
    " occasion. Mostly, this should be the CursorMoved event, which fortunately
    " isn't fired when 'incsearch' highlights the potential match, only when the
    " operator results in a cursor move. The other events are only there to be
    " safe.
    augroup OperatorPendingSearchOff
	autocmd!
	autocmd BufLeave,WinLeave,InsertEnter,CursorHold,CursorMoved * let s:isOperatorPendingSearch = 0 | autocmd! OperatorPendingSearchOff
    augroup END

    return a:searchOperator
endfunction

function! s:SearchText( text, count, isWholeWordSearch, isBackward, cwordStartPosition )
    let s:isStarSearch = 1
    let s:quickSearchPattern = ingo#regexp#FromLiteralText(a:text, a:isWholeWordSearch, '')
    return s:DoSearch(a:count, a:isBackward, a:cwordStartPosition)
endfunction
function! s:SearchCWord( isWholeWordSearch, isBackward )
    let l:cwordStartPosition = (a:isBackward ? SearchSpecialCWord#GetStartPosition(s:quickSearchPattern) : [])
    return s:SearchText(expand('<cword>'), v:count1, a:isWholeWordSearch, a:isBackward, l:cwordStartPosition)
endfunction
function! s:SearchSelection( text, count, isWholeWordSearch, isBackward )
    return s:SearchText(a:text, a:count, a:isWholeWordSearch, a:isBackward, [])
endfunction
function! SearchAsQuickJump#JumpAfterSearchCommand( isBackward )
    call histdel('search', -1)

    " If the SearchRepeat plugin is installed, it provides the [count] given to
    " the last search command for other consumers. Otherwise, we do not support
    " [count], as that would mean remapping the / and ? commands just to record
    " the [count].
    let l:count = ((exists('g:lastSearchCount') && g:lastSearchCount) ? g:lastSearchCount : 1)

    return s:DoSearch(l:count, a:isBackward)
endfunction
function! s:QuickSearch()
    if getcmdtype() ==# '/'
	let l:isBackward = 0
    elseif getcmdtype() ==# '?'
	let l:isBackward = 1
    else
	" This is no search, remove the history marker and conclude the command
	" line with a normal Enter.
	return repeat("\<BS>", s:NoHistoryMarkerLen) . "\<CR>"
    endif

    let s:isStarSearch = 0
    let s:quickSearchPattern = strpart(getcmdline(), 0, strlen(getcmdline()) - s:NoHistoryMarkerLen)

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


"- mappings -------------------------------------------------------------------

" The quick search pattern should not pollute the normal search history.
" However, Vim always appends to the history, even if command-line mode is
" aborted via <Esc> or CTRL-C (probably to be able to go back and finish an
" aborted command). Thus, the quick search pattern has to be removed from the
" search history.
" To remove without side effects, we must ensure that the quick search pattern
" wasn't contained in the search history before. In such a case, the history
" item would be moved from its original position to the end of the history, and
" by deleting it, the item would completely disappear from the history!
" Thus, a history marker is appended to the entered search pattern by the
" mapping that triggers the quick jump, and later stripped off the search
" pattern. The marker should be a string that the user would never enter on his
" own, so that we can be reasonably sure that the resulting search pattern is
" not yet contained in the search history. We chose two obscure control
" characters (CTRL-_ (0x1f) Unit Separator and CTRL-] (0x1d) Group Separator)
" which are not valid Vim commands in command-line mode.
let s:NoHistoryMarkerLen = 3
cnoremap <SID>NoHistoryMarker <C-_><C-]>
cnoremap <expr> <SID>QuickSearch <SID>QuickSearch()
" If :cnoremap is used, the mapping doesn't trigger expansion of :cabbrev any
" more. The only way to work around this is by using :cmap and prepending a
" <Space> (which is considered part of the NoHistoryMarker and later removed
" with it).
cmap <silent> <S-CR> <Space><SID>NoHistoryMarker<SID>QuickSearch


if g:SearchAsQuickJump_DefineStarCommands
nnoremap <silent> <Plug>SearchAsQuickJumpStar  :<C-u>if ! <SID>SearchCWord(1, 0)<Bar>echoerr ingo#err#Get()<Bar>endif
nnoremap <silent> <Plug>SearchAsQuickJumpHash  :<C-u>if ! <SID>SearchCWord(1, 1)<Bar>echoerr ingo#err#Get()<Bar>endif
nnoremap <silent> <Plug>SearchAsQuickJumpGStar :<C-u>if ! <SID>SearchCWord(0, 0)<Bar>echoerr ingo#err#Get()<Bar>endif
nnoremap <silent> <Plug>SearchAsQuickJumpGHash :<C-u>if ! <SID>SearchCWord(0, 1)<Bar>echoerr ingo#err#Get()<Bar>endif
vnoremap <silent> <Plug>SearchAsQuickJumpStar  :<C-u>if ! <SID>SearchSelection(ingo#selection#Get(), v:count1, 0, 0)<Bar>echoerr ingo#err#Get()<Bar>endif
vnoremap <silent> <Plug>SearchAsQuickJumpHash  :<C-u>if ! <SID>SearchSelection(ingo#selection#Get(), v:count1, 0, 1)<Bar>echoerr ingo#err#Get()<Bar>endif
if ! hasmapto('<Plug>SearchAsQuickJumpStar', 'n')
    nmap q* <Plug>SearchAsQuickJumpStar
endif
if ! hasmapto('<Plug>SearchAsQuickJumpHash', 'n')
    nmap q# <Plug>SearchAsQuickJumpHash
endif
if ! hasmapto('<Plug>SearchAsQuickJumpGStar', 'n')
    nmap gq* <Plug>SearchAsQuickJumpGStar
endif
if ! hasmapto('<Plug>SearchAsQuickJumpGHash', 'n')
    nmap gq# <Plug>SearchAsQuickJumpGHash
endif
if ! hasmapto('<Plug>SearchAsQuickJumpStar', 'x')
    xmap q* <Plug>SearchAsQuickJumpStar
endif
if ! hasmapto('<Plug>SearchAsQuickJumpHash', 'x')
    xmap q# <Plug>SearchAsQuickJumpHash
endif
endif

onoremap <expr> / <SID>OperatorPendingSearch('/')
onoremap <expr> ? <SID>OperatorPendingSearch('?')

nmap <silent> goq <Plug>SearchAsQuickJumpNext
nmap <silent> goQ <Plug>SearchAsQuickJumpPrev


" Integration into SearchRepeat.vim
try
    call SearchRepeat#Register("\<Plug>SearchAsQuickJumpNext", '/<S-CR>', 'gnq', '/quick/', 'Quick search forward', '')
    call SearchRepeat#Register("\<Plug>SearchAsQuickJumpPrev", '?<S-CR>', 'gnQ', '?quick?', 'Quick search backward', '')
    nnoremap <silent> gnq :<C-U>call SearchRepeat#Execute("\<Plug>SearchAsQuickJumpNext", "\<Plug>SearchAsQuickJumpPrev", 2, {'hlsearch': 0})<CR>
    nnoremap <silent> gnQ :<C-U>call SearchRepeat#Execute("\<Plug>SearchAsQuickJumpPrev", "\<Plug>SearchAsQuickJumpNext", 2, {'hlsearch': 0})<CR>
catch /^Vim\%((\a\+)\)\=:E117/	" catch error E117: Unknown function
endtry

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
