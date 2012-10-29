" SearchAsQuickJump.vim: Quick search without 'hlsearch', setting of search
" pattern and search history. 
"
" DESCRIPTION:
"   I use the built-in search (|/|, |?|, |n| and |N|) for two different
"   purposes:
"   1. For quick mouseless navigation to a place not far away, or as a {motion}
"      e.g. in d/{pattern}/. 
"   2. For actual searches, when I'm looking for and examining all occurrences
"      inside the buffer or even multiple windows. 
"
"   Unfortunately, there's a tension in how to configure the search-related
"   settings: For quick searches, highlighting of matches is not important, as
"   my eyes are already focused on the target text, I just want to get there
"   with the fewest keystrokes, and figured that a search for "/:le" is faster
"   than "3fA4whhh". Because the search pattern is mostly incomplete made-up
"   rubbish, the highlighting should not continue to distract after the search;
"   it should be off (but 'incsearch' helps to recognize when enough of the
"   pattern is typed to reach the desired location). Likewise, the search
"   pattern is useless in the search history and as the last pattern for the |n|
"   command, as I am unlikely to repeat that search.
"   On the other hand, for actual searches, history recall, repeated search and
"   highlighting of matches are vital and central to the task. 
"
"   How can this be reconciled? This plugin sets up alternative mappings to the
"   <CR> key which normally concludes entering of the search pattern in
"   command-line mode. By pressing <S-CR>, a quick search is triggered instead
"   of a normal one. This quick search does not use search highlighting and the
"   search pattern is not added to the search history, so it can be used without
"   affecting the normal search. 
"   
"   Next / previous matches can be jumped to via separate mappings, but not via
"   the default |n| / |N| commands. (Even if the integration with the
"   SearchRepeat plugin is used; contrary to most other integrations, this quick
"   search must be explicitly activated via the |gnq| / |gnQ| mapping. )
"
" USAGE:
" /{pattern}[/]<S-CR>	When a search via |/| or |?| is sent off by pressing
" ?{pattern}[?]<S-CR>	<S-CR>, a quick forward / backward search is performed.
"			Matches will not be highlighted via 'hlsearch', and the
"			search pattern will not be added to the search history
"			or used as the last pattern for |n| / |N| search
"			repeats. 
"			Use this for a quick search without the formality and
"			persistence of a normal search, which can still be
"			obtained by concluding the pattern input with the
"			default <CR> at the end. 
"
" [count]goq / goQ	Search forward / backward to the [count]'th occurrence
"			of the quick search pattern. This is the equivalent to
"			the default |n| / |N| search repeat commands. 
"
" The following commands are optional; cp. the Configuration section below. 
" q*, q#		Search forward / backward for the [count]'th occurrence
"			of the word nearest to the cursor.
" gq*, gq#		Like above, but don't put "\<" and "\>" around the word.
"			This makes the search also find matches that are not a
"			whole word. 
" {Visual}q*		Do a quick search forward / backward for the [count]'th
" {Visual}q#	    	occurrence of the current selection, like the built-in
"			|g*| and |g#| commands. 
"
"			These mappings are based on the built-in |star| and |#|
"			commands. Like with them, 'ignorecase' is used,
"			'smartcase' is not. 
"
"   If the SearchRepeat plugin is installed, a parallel set of "go now and for
"   next searches" mappings (starting with 'gn...' instead of 'go...') is
"   installed. These mappings have the same effect, but in addition re-program
"   the 'n/N' keys to repeat this particular search (until another gn... search
"   is used). 
"
" INSTALLATION:
"   Put the script into your user or system Vim plugin directory (e.g.
"   ~/.vim/plugin). 

" DEPENDENCIES:
"   - Requires Vim 7.0 or higher. 
"   - ingointegration.vim autoload script. 
"   - ingosearch.vim autoload script. 
"   - SearchSpecial.vim autoload script. 
"   - SearchSpecialCWord.vim autoload script. 
"   - SearchRepeat.vim autoload script (optional integration). 

" CONFIGURATION:
"   If you want commands like the built-in '*', 'g*', '#' and 'g#' commands (but
"   prefixed with 'q'), use: 
"	:let g:SearchAsQuickJump_DefineStarCommands = 1
"
" INTEGRATION:
" LIMITATIONS:
" ASSUMPTIONS:
" KNOWN PROBLEMS:
" TODO:
" - Handle trailing /, ?. 
" - Warning if {offset} is specified. 
" - Handle {offset}. 
"
" Copyright: (C) 2009-2011 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
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
    call SearchSpecial#SearchWithout(s:quickSearchPattern, a:isBackward, '', 'quick', '', a:count, {'isStarSearch': s:isStarSearch, 'currentMatchPosition': (a:0 ? a:1 : [])})
endfunction
nnoremap <silent> <Plug>SearchAsQuickJumpNext :<C-u>call <SID>DoSearch(v:count1, 0)<CR>
nnoremap <silent> <Plug>SearchAsQuickJumpPrev :<C-u>call <SID>DoSearch(v:count1, 1)<CR>


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
    let s:quickSearchPattern = ingosearch#LiteralTextToSearchPattern(a:text, a:isWholeWordSearch, '')
    call s:DoSearch(a:count, a:isBackward, a:cwordStartPosition)
endfunction
function! s:SearchCWord( isWholeWordSearch, isBackward )
    let l:cwordStartPosition = (a:isBackward ? SearchSpecialCWord#GetStartPosition(s:quickSearchPattern) : [])
    call s:SearchText(expand('<cword>'), v:count1, a:isWholeWordSearch, a:isBackward, l:cwordStartPosition)
endfunction
function! s:SearchSelection( text, count, isWholeWordSearch, isBackward )
    call s:SearchText(a:text, a:count, a:isWholeWordSearch, a:isBackward, [])
endfunction
function! SearchAsQuickJump#JumpAfterSearchCommand( isBackward )
    call histdel('search', -1)

    " If the SearchRepeat plugin is installed, it provides the [count] given to
    " the last search command for other consumers. Otherwise, we do not support
    " [count], as that would mean remapping the / and ? commands just to record
    " the [count]. 
    let l:count = ((exists('g:lastSearchCount') && g:lastSearchCount) ? g:lastSearchCount : 1)

    call s:DoSearch(l:count, a:isBackward)
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
	return "\<C-c>:call SearchAsQuickJump#JumpAfterSearchCommand(" . l:isBackward . ")\<CR>"
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
nnoremap <silent> <Plug>SearchAsQuickJumpStar  :<C-u>call <SID>SearchCWord(1, 0)<CR>
nnoremap <silent> <Plug>SearchAsQuickJumpHash  :<C-u>call <SID>SearchCWord(1, 1)<CR>
nnoremap <silent> <Plug>SearchAsQuickJumpGStar :<C-u>call <SID>SearchCWord(0, 0)<CR>
nnoremap <silent> <Plug>SearchAsQuickJumpGHash :<C-u>call <SID>SearchCWord(0, 1)<CR>
vnoremap <silent> <Plug>SearchAsQuickJumpStar  :<C-u>call <SID>SearchSelection(ingointegration#GetVisualSelection(), v:count1, 0, 0)<CR>
vnoremap <silent> <Plug>SearchAsQuickJumpHash  :<C-u>call <SID>SearchSelection(ingointegration#GetVisualSelection(), v:count1, 0, 1)<CR>
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
