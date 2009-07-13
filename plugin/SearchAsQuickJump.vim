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
"   pattern is useless in the search history, as I am unlikely to repeat that
"   search.
"   On the other hand, for actual searches, both history recall and highlighting
"   of matches are vital and central to the task. 
"
"   How can this be reconciled? This plugin sets up alternative mappings to the
"   <CR> key which normally concludes entering of the search pattern in
"   command-line mode. By pressing <S-CR>, a quick search is triggered instead
"   of a normal one. This quick search does not use search highlighting and the
"   search pattern is not added to the search history, so it can be used without
"   affecting the normal search. 
"   
"   Next / previous matches can be jumped to via separate mappings, or (if the
"   integration with the SearchRepeat plugin is used) also via the default |n| /
"   |N| commands. 
"
" USAGE:
" /{pattern}[/]<S-CR>	When a search via |/| or |?| is sent off by pressing
" ?{pattern}[?]<S-CR>	<S-CR>, a quick forward / backward search is performed.
"			Matches will not be highlighted via 'hlsearch', and the
"			search pattern will not be added to the search history. 
"			Use this for a quick search without the formality and
"			persistence of a normal search, which can still be
"			obtained by pressing <CR> at the end. 
"
"			If the SearchRepeat plugin is installed, the 'n/N' keys
"			are reprogrammed to repeat the quick search. 
"
" q*, q#		Search forward / backward for the [count]'th occurrence
"			of the word nearest to the cursor.
" gq*, gq#		Like above, but don't put "\<" and "\>" around the word.
"			This makes the search also find matches that are not a
"			whole word. 
" {Visual}q*		Do a quick search forward / backward for the [count]'th
" {Visual}q#	    	occurrence of the current selection, like the built-in
"			|g*| and |g#| commands. 
"
"			If the SearchRepeat plugin is installed, the 'n/N' keys
"			are reprogrammed to repeat the quick search. 
"
" [count]goq / goQ	Search forward / backward to the [count]'th occurrence
"			of the quick search pattern. 
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
"   - SearchHighlighting.vim autoload script. 
"   - SearchSpecial.vim autoload script. 
"   - SearchSpecialCWord.vim autoload script. 
"   - SearchRepeat.vim autoload script (optional integration). 

" CONFIGURATION:
" INTEGRATION:
" LIMITATIONS:
" ASSUMPTIONS:
" KNOWN PROBLEMS:
" TODO:
" - Handle trailing /, ?. 
" - Warning if {offset} is specified. 
" - Handle {offset}. 
" - No 'smartcase' for "Star" and "Hash" mappings. 
"
" Copyright: (C) 2009 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
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

"- use of SearchSpecial library -----------------------------------------------
function! s:GetQuickSearchPattern()
    return s:quickSearchPattern
endfunction
nnoremap <silent> <Plug>SearchAsQuickJumpNext :<C-u>call SearchSpecial#SearchWithout(<SID>GetQuickSearchPattern(), 0, '', 'quick', '', v:count1)<CR>
nnoremap <silent> <Plug>SearchAsQuickJumpPrev :<C-u>call SearchSpecial#SearchWithout(<SID>GetQuickSearchPattern(), 1, '', 'quick', '', v:count1)<CR>


"- functions ------------------------------------------------------------------
function! s:Jump( count, isBackward, ... )
    call SearchSpecial#SearchWithout(s:quickSearchPattern, a:isBackward, '', 'quick', '', a:count, (a:0 ? a:1 : [0, 0]))
    if a:isBackward
	silent! call SearchRepeat#Set("\<Plug>SearchAsQuickJumpPrev", "\<Plug>SearchAsQuickJumpNext", 2, {'hlsearch': 0})
    else
	silent! call SearchRepeat#Set("\<Plug>SearchAsQuickJumpNext", "\<Plug>SearchAsQuickJumpPrev", 2, {'hlsearch': 0})
    endif
endfunction
function! s:SearchCWord( isWholeWordSearch, isBackward )
    let s:quickSearchPattern = SearchHighlighting#GetSearchPattern(expand('<cword>'), a:isWholeWordSearch, '')
    let l:cwordStartPosition = (a:isBackward ? SearchSpecialCWord#GetStartPosition(s:quickSearchPattern) : [0, 0])
    call s:Jump(v:count1, a:isBackward, l:cwordStartPosition)
endfunction
function! s:SearchSelection( text, count, isWholeWordSearch, isBackward )
    let s:quickSearchPattern = SearchHighlighting#GetSearchPattern(a:text, a:isWholeWordSearch, '')
    call s:Jump(a:count, a:isBackward)
endfunction
function! SearchAsQuickJump#Jump( isBackward )
    call histdel('/', -1)
    call s:Jump(1, a:isBackward)
endfunction
function! s:QuickSearch()
    if getcmdtype() ==# '/'
	let l:isBackward = 0
    elseif getcmdtype() ==# '?'
	let l:isBackward = 1
    else
	return "\<CR>"
    endif

    let s:quickSearchPattern = strpart(getcmdline(), 0, strlen(getcmdline()) - s:NoHistoryMarkerLen)
    " Note: Must use CTRL-C to abort search command-line; <Esc> somehow doesn't
    " work. 
    return "\<C-c>:call SearchAsQuickJump#Jump(" . l:isBackward . ")\<CR>"
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


nnoremap <Plug>SearchAsQuickJumpStar  :<C-u>call <SID>SearchCWord(1, 0)<CR>
nnoremap <Plug>SearchAsQuickJumpHash  :<C-u>call <SID>SearchCWord(1, 1)<CR>
nnoremap <Plug>SearchAsQuickJumpGStar :<C-u>call <SID>SearchCWord(0, 0)<CR>
nnoremap <Plug>SearchAsQuickJumpGHash :<C-u>call <SID>SearchCWord(0, 1)<CR>
vnoremap <Plug>SearchAsQuickJumpStar  :<C-u>let save_unnamedregister = @@<Bar>let save_count=v:count1<CR>gvy:<C-u>call <SID>SearchSelection(@@, save_count, 0, 0)<Bar>let @@ = save_unnamedregister<Bar>unlet save_unnamedregister<Bar>unlet save_count<CR>
vnoremap <Plug>SearchAsQuickJumpHash  :<C-u>let save_unnamedregister = @@<Bar>let save_count=v:count1<CR>gvy:<C-u>call <SID>SearchSelection(@@, save_count, 0, 1)<Bar>let @@ = save_unnamedregister<Bar>unlet save_unnamedregister<Bar>unlet save_count<CR>
if ! hasmapto('<Plug>SearchAsQuickJumpStar', 'n')
    nmap <silent> q* <Plug>SearchAsQuickJumpStar
endif
if ! hasmapto('<Plug>SearchAsQuickJumpHash', 'n')
    nmap <silent> q# <Plug>SearchAsQuickJumpHash
endif
if ! hasmapto('<Plug>SearchAsQuickJumpGStar', 'n')
    nmap <silent> gq* <Plug>SearchAsQuickJumpGStar
endif
if ! hasmapto('<Plug>SearchAsQuickJumpGHash', 'n')
    nmap <silent> gq# <Plug>SearchAsQuickJumpGHash
endif
if ! hasmapto('<Plug>SearchAsQuickJumpStar', 'v')
    vmap <silent> q* <Plug>SearchAsQuickJumpStar
endif
if ! hasmapto('<Plug>SearchAsQuickJumpHash', 'v')
    vmap <silent> q# <Plug>SearchAsQuickJumpHash
endif

nmap <silent> goq <Plug>SearchAsQuickJumpNext
nmap <silent> goQ <Plug>SearchAsQuickJumpPrev


" Integration into SearchRepeat.vim
try
    call SearchRepeat#Register("\<Plug>SearchAsQuickJumpNext", '/<S-CR>', 'gnq', 'Quick search forward', '')
    call SearchRepeat#Register("\<Plug>SearchAsQuickJumpPrev", '?<S-CR>', 'gnQ', 'Quick search backward', '')
    nnoremap <silent> gnq :<C-U>call SearchRepeat#Execute("\<Plug>SearchAsQuickJumpNext", "\<Plug>SearchAsQuickJumpPrev", 2, {'hlsearch': 0})<CR>
    nnoremap <silent> gnQ :<C-U>call SearchRepeat#Execute("\<Plug>SearchAsQuickJumpPrev", "\<Plug>SearchAsQuickJumpNext", 2, {'hlsearch': 0})<CR>
catch /^Vim\%((\a\+)\)\=:E117/	" catch error E117: Unknown function
endtry

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
