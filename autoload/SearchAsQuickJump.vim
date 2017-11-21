" SearchAsQuickJump.vim: Quick search without affecting 'hlsearch', search pattern and history.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"   - ingo/regexp.vim autoload script
"   - SearchSpecial.vim autoload script
"   - SearchSpecial/CWord.vim autoload script
"   - SearchSpecial/Offset.vim autoload script

" Copyright: (C) 2009-2017 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
let s:save_cpo = &cpo
set cpo&vim

"- use of SearchSpecial library -----------------------------------------------

function! SearchAsQuickJump#DoSearch( count, isBackward, ... )
    let [l:offsetSearchFlags, l:BeforeFirstSearchAction, l:AfterFinalSearchAction] = SearchSpecial#Offset#GetAction(s:quickSearchOffset)
    return SearchSpecial#SearchWithout(s:quickSearchPattern, a:isBackward, '', 'quick', '', a:count,
    \   {
    \       'isStarSearch': s:isStarSearch,
    \       'currentMatchPosition': (a:0 ? a:1 : []),
    \       'additionalSearchFlags': 'e' . l:offsetSearchFlags,
    \       'BeforeFirstSearchAction': l:BeforeFirstSearchAction,
    \       'AfterFinalSearchAction': l:AfterFinalSearchAction,
    \   }
    \)
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

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
