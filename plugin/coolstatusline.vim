function! s:SetHighlightGroup(group, fg_colours, bg_colours)
    let highlight_cmd = 'hi '.a:group

    if a:fg_colours[0] != ''
        let highlight_cmd .= ' ctermfg='.a:fg_colours[0]
    endif

    if a:bg_colours[0] != ''
        let highlight_cmd .= ' ctermbg='.a:bg_colours[0]
    endif

    if a:fg_colours[1] != ''
        let highlight_cmd .= ' guifg='.a:fg_colours[1]
    endif

    if a:bg_colours[1] != ''
        let highlight_cmd .= ' guibg='.a:bg_colours[1]
    endif

    exec highlight_cmd
endfunction

function! s:GetColour(group, attr, gui_mode)
    return synIDattr(synIDtrans(hlID(a:group)), a:attr, a:gui_mode)
endfunction

function! s:GetColour2(group, attr)
    return [
        \ s:GetColour(a:group, a:attr, 'cterm'),
        \ s:GetColour(a:group, a:attr, 'gui'  )
        \ ]
endfunction

function! coolstatusline#Mode()
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

    call s:SetHighlightGroup('User4', l:mode_colour, '')
    call s:SetHighlightGroup('User5', '', l:mode_colour)

   return l:mode_text
endfunction

function! s:SetStatusHighlightGroups()

    let colour_text     = s:GetColour2('Cursor'      , 'bg')
    let colour_bg_light = s:GetColour2('StatusLine'  , 'bg')
    let colour_bg_dark  = s:GetColour2('CursorLineNr', 'bg')

    let g:colour_normal = s:GetColour2('Title'  , 'fg')
    let g:colour_insert = s:GetColour2('MoreMsg', 'fg')

    call s:SetHighlightGroup('User1', colour_text    , colour_bg_dark )
    call s:SetHighlightGroup('User2', colour_bg_light, colour_bg_dark )
    call s:SetHighlightGroup('User3', colour_text    , colour_bg_light)
    call s:SetHighlightGroup('User4', ''             , colour_bg_light)
    call s:SetHighlightGroup('User5', colour_bg_dark , ''             )

    call coolstatusline#Mode()
endfunction

function! coolstatusline#GetGitBranch()
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

function! coolstatusline#GetHunks()
    let hunks = GitGutterGetHunkSummary()
    if hunks[0] == 0 && hunks[1] == 0 && hunks[2] == 0
        return ""
    else
        return "+".hunks[0]." ~".hunks[1]." -".hunks[2]
    endif
endfunction

function! s:SetStatusLine()
    call s:SetStatusHighlightGroups()

    if !exists('g:coolstatusline_use_symbols')
        let g:coolstatusline_use_symbols != 0
    endif

    " left-align everything past this point
    let &stl="%<"

    let &stl.="%5* "
    let &stl.="%{coolstatusline#Mode()} "

    if g:coolstatusline_use_symbols
        let &stl.="%4*"
    endif

    let &stl.="%3* "

    if exists('*GitGutterGetHunkSummary')
        let &stl.="%(%{coolstatusline#GetHunks()} %)"
    endif

    if exists('*fugitive#head')
        let &stl.="%( %{coolstatusline#GetGitBranch()} %)"
    endif

    if g:coolstatusline_use_symbols
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

    if g:coolstatusline_use_symbols
        let &stl.="%2*"
    endif

    let &stl.="%3* "
    let &stl.="%{&fileformat} "

    if g:coolstatusline_use_symbols
        let &stl.="%4*"
    endif

    let &stl.="%5* "
    let &stl.="%2.p%%  %2.l/%L☰ : %-2.c "
endfunction

function! coolstatusline#Refresh()
    call s:SetStatusHighlightGroups()
endfunction

augroup status_line
    autocmd!
    autocmd ColorScheme,VimEnter * call s:SetStatusLine()
augroup END
