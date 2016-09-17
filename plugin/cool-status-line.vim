function! SetHighlightGroup(group, fg_colour, bg_colour)
    let highlight_cmd = 'hi '.a:group

    if a:fg_colour[0] != ''
        let highlight_cmd .= ' ctermfg='.a:fg_colour[0]
    endif

    if a:bg_colour[0] != ''
        let highlight_cmd .= ' ctermbg='.a:bg_colour[0]
    endif

    if a:fg_colour[1] != ''
        let highlight_cmd .= ' guifg='.a:fg_colour[1]
    endif

    if a:bg_colour[1] != ''
        let highlight_cmd .= ' guibg='.a:bg_colour[1]
    endif

    exec highlight_cmd
endfunction

function! Mode()
    let l:mode = mode()

    if l:mode ==# "n"
        let l:mode_colour = g:colour_normal
        let l:mode_text   = "N"
    elseif l:mode ==# "i"
        let l:mode_colour = g:colour_insert
        let l:mode_text   = "I"
    elseif l:mode ==# "R"
        let l:mode_colour = g:colour_insert
        let l:mode_text   = "R"
    elseif l:mode ==# "v"
        let l:mode_colour = g:colour_insert
        let l:mode_text   = "V"
    elseif l:mode ==# "V"
        let l:mode_colour = g:colour_insert
        let l:mode_text   = "V-LINE"
    elseif l:mode ==# ""
        let l:mode_colour = g:colour_insert
        let l:mode_text   = "V-BLOCK"
    else
        let l:mode_colour = g:colour_insert
        let l:mode_text   = l:mode
    endif

    call SetHighlightGroup('User4', l:mode_colour, '')
    call SetHighlightGroup('User5', '', l:mode_colour)

   return l:mode_text
endfunction

function! GetColour(group, attr, gui_mode)
    return synIDattr(synIDtrans(hlID(a:group)), a:attr, a:gui_mode)
endfunction

function! GetColour2(group, attr)
    return [
        \ GetColour(a:group, a:attr, 'cterm'),
        \ GetColour(a:group, a:attr, 'gui'  )
        \ ]
endfunction

function! SetStatusHighlightGroups()

    let colour_text     = GetColour2('Cursor'      , 'bg')
    let colour_bg_light = GetColour2('StatusLine'  , 'bg')
    let colour_bg_dark  = GetColour2('CursorLineNr', 'bg')

    let g:colour_normal = GetColour2('Title'  , 'fg')
    let g:colour_insert = GetColour2('MoreMsg', 'fg')

    call SetHighlightGroup('User1', colour_text    , colour_bg_dark )
    call SetHighlightGroup('User2', colour_bg_light, colour_bg_dark )
    call SetHighlightGroup('User3', colour_text    , colour_bg_light)
    call SetHighlightGroup('User4', ''             , colour_bg_light)
    call SetHighlightGroup('User5', colour_bg_dark , ''             )

    call Mode()
endfunction

function! GetGitBranch()
  if !exists('*fugitive#head')
    return ''
  endif

  let name = fugitive#head(7)
  if empty(name)
    let dir = fugitive#extract_git_dir(expand('%'))
    if empty(dir)
      let name = ''
    else
      try
        let line = join(readfile(dir . '/HEAD'))
        if strpart(line, 0, 16) == 'ref: refs/heads/'
          let name = strpart(line, 16)
        else
          " raw commit hash
          let name = strpart(line, 0, 7)
        endif
      catch
        let name = ''
      endtry
    endif
  endif
  return name
endfunction

function! GetHunks()
    let hunks = GitGutterGetHunkSummary()
    if hunks[0] == 0 && hunks[1] == 0 && hunks[2] == 0
        return ""
    else
        return "+".hunks[0]." ~".hunks[1]." -".hunks[2]
    endif
endfunction

function! SetStatusLine()
    call SetStatusHighlightGroups()

    let use_symbols = 1
    let show_hunks  = 1
    let show_branch = 1

    " left-align everything past this point
    let &stl="%<"

    let &stl.="%5* "
    let &stl.="%{Mode()} "

    if use_symbols
        let &stl.="%4*"
    endif

    let &stl.="%3*"

    if show_hunks
        let &stl.="%( %{GetHunks()} %)"
    endif

    if show_branch
        let &stl.="%( %{GetGitBranch()} %)"
    endif

    if use_symbols
        let &stl.="%2*"
    endif

    " tail filename
    let &stl.="%1* %t"

    " read only, modified, modifiable flags in brackets
    let &stl.="%([%R%M]%) "

    " right-align everything past this point
    let &stl.="%="

    " readonly flag
    let &stl.="%(%{(&ro!=0?'[readonly]':'')} %)"

    let &stl.="%( %{&filetype} %)"

    if use_symbols
        let &stl.="%2*"
    endif

    let &stl.="%3* "
    let &stl.="%{&fileformat} "

    if use_symbols
        let &stl.="%4*"
    endif

    let &stl.="%5* "
    let &stl.="%2.p%%  %3.l/%L☰ : %-2.c "
endfunction

augroup status_line
    au!
    au ColorScheme,VimEnter * call SetStatusLine()
augroup END
