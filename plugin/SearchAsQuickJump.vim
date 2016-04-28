" SearchAsQuickJump.vim: Quick search without affecting 'hlsearch', search pattern and history.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"   - SearchAsQuickJump.vim autoload script
"   - ingo/err.vim autoload script
"   - ingo/selection.vim autoload script
"   - SearchRepeat.vim autoload script (optional integration)

" Copyright: (C) 2009-2016 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   2.00.024	29-Apr-2016	Adapt to changed SearchRepeat.vim version 2.00
"				interface. Change activation mappings.
"   1.00.023	31-Jan-2015	Allow to remap the <S-CR> cmap, too.
"				Enable the star commands by default.
"   1.00.022	26-May-2014	Adapt <Plug>-mapping naming.
"				Make go... mappings configurable.
"				Adapt to polished SearchRepeat interface.
"	021	05-May-2014	FIX: The special control character <C-]> isn't
"				inserted into command-line any more with Vim
"				7.4.264 (works with 7.3.823), probably because
"				of the |c_CTRL-]| command. Switch
"				<SID>NoHistoryMarker to <C-_><C-_> instead.
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

" Avoid installing twice or when in unsupported Vim version.
if exists('g:loaded_SearchAsQuickJump') || (v:version < 700)
    finish
endif
let g:loaded_SearchAsQuickJump = 1
let s:save_cpo = &cpo
set cpo&vim

"- configuration --------------------------------------------------------------

if ! exists('g:SearchAsQuickJump_DefineStarCommands')
    let g:SearchAsQuickJump_DefineStarCommands = 1
endif


"- mappings -------------------------------------------------------------------

nnoremap <silent> <Plug>(SearchAsQuickJumpNext) :<C-u>if ! SearchAsQuickJump#DoSearch(v:count1, 0)<Bar>echoerr ingo#err#Get()<Bar>endif<CR>
nnoremap <silent> <Plug>(SearchAsQuickJumpPrev) :<C-u>if ! SearchAsQuickJump#DoSearch(v:count1, 1)<Bar>echoerr ingo#err#Get()<Bar>endif<CR>

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
" not yet contained in the search history. We choose an obscure control
" character (CTRL-_ (0x1f) Unit Separator) which is not a valid Vim command in
" command-line mode.
cnoremap <SID>(NoHistoryMarker) <C-_><C-_>
" Note: This needs to correspond to s:NoHistoryMarkerLen in
" autoload/SearchAsQuickJump.vim
cnoremap <expr> <SID>(QuickSearch) SearchAsQuickJump#QuickSearch()
" If :cnoremap is used, the mapping doesn't trigger expansion of :cabbrev any
" more. The only way to work around this is by using :cmap and prepending a
" <Space> (which is considered part of the NoHistoryMarker and later removed
" with it).
cmap <silent> <Plug>(SearchAsQuickJump) <Space><SID>(NoHistoryMarker)<SID>(QuickSearch)
if ! hasmapto('<Plug>(SearchAsQuickJump)', 'c')
    cmap <S-CR> <Plug>(SearchAsQuickJump)
endif


if g:SearchAsQuickJump_DefineStarCommands
nnoremap <silent> <Plug>(SearchAsQuickJumpStar)  :<C-u>if ! SearchAsQuickJump#SearchCWord(1, 0)<Bar>echoerr ingo#err#Get()<Bar>endif<CR>
nnoremap <silent> <Plug>(SearchAsQuickJumpHash)  :<C-u>if ! SearchAsQuickJump#SearchCWord(1, 1)<Bar>echoerr ingo#err#Get()<Bar>endif<CR>
nnoremap <silent> <Plug>(SearchAsQuickJumpGStar) :<C-u>if ! SearchAsQuickJump#SearchCWord(0, 0)<Bar>echoerr ingo#err#Get()<Bar>endif<CR>
nnoremap <silent> <Plug>(SearchAsQuickJumpGHash) :<C-u>if ! SearchAsQuickJump#SearchCWord(0, 1)<Bar>echoerr ingo#err#Get()<Bar>endif<CR>
vnoremap <silent> <Plug>(SearchAsQuickJumpStar)  :<C-u>if ! SearchAsQuickJump#SearchSelection(ingo#selection#Get(), v:count1, 0, 0)<Bar>echoerr ingo#err#Get()<Bar>endif<CR>
vnoremap <silent> <Plug>(SearchAsQuickJumpHash)  :<C-u>if ! SearchAsQuickJump#SearchSelection(ingo#selection#Get(), v:count1, 0, 1)<Bar>echoerr ingo#err#Get()<Bar>endif<CR>
if ! hasmapto('<Plug>SearchAsQuickJumpStar', 'n')
    nmap q* <Plug>(SearchAsQuickJumpStar)
endif
if ! hasmapto('<Plug>SearchAsQuickJumpHash', 'n')
    nmap q# <Plug>(SearchAsQuickJumpHash)
endif
if ! hasmapto('<Plug>SearchAsQuickJumpGStar', 'n')
    nmap gq* <Plug>(SearchAsQuickJumpGStar)
endif
if ! hasmapto('<Plug>SearchAsQuickJumpGHash', 'n')
    nmap gq# <Plug>(SearchAsQuickJumpGHash)
endif
if ! hasmapto('<Plug>SearchAsQuickJumpStar', 'x')
    xmap q* <Plug>(SearchAsQuickJumpStar)
endif
if ! hasmapto('<Plug>SearchAsQuickJumpHash', 'x')
    xmap q# <Plug>(SearchAsQuickJumpHash)
endif
endif

onoremap <expr> / SearchAsQuickJump#OperatorPendingSearch('/')
onoremap <expr> ? SearchAsQuickJump#OperatorPendingSearch('?')

if ! hasmapto('<Plug>(SearchAsQuickJumpNext)', 'n')
    nmap goq <Plug>(SearchAsQuickJumpNext)
endif
if ! hasmapto('<Plug>(SearchAsQuickJumpPrev)', 'n')
    nmap gOq <Plug>(SearchAsQuickJumpPrev)
endif


"- Integration into SearchRepeat.vim -------------------------------------------

try
    call SearchRepeat#Define(
    \	'<Plug>(SearchAsQuickJumpNext)', '<Plug>(SearchAsQuickJumpPrev)',
    \   '/<S-CR>', 'q', 'quick', 'Quick search', '',
    \	"2, {'hlsearch': 0}"
    \)
catch /^Vim\%((\a\+)\)\=:E117:/	" catch error E117: Unknown function
endtry

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
