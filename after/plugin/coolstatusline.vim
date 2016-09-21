if &cp || v:version < 702 || (exists('g:loaded_coolstatusline') && g:loaded_coolstatusline)
    finish
endif

let g:loaded_coolstatusline = 1

let s:has_fugitive   = exists('g:loaded_fugitive'  )
let s:has_vcscommand = exists('g:loaded_VCSCommand')
let s:has_gitgutter  = exists('g:loaded_gitgutter' )
let s:has_signify    = exists('g:loaded_signify'   )

if !exists('g:coolstatusline_use_symbols')
    let g:coolstatusline_use_symbols != 0
endif

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

    call coolstatusline#GetMode()
endfunction

function! coolstatusline#GetMode()
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

function! coolstatusline#GetGitBranch()
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

function! s:GetBranchFromVCSCommand()
    if exists('*VCSCommandEnableBufferSetup') && &ft != 'dirvish'
        call VCSCommandEnableBufferSetup()
        if exists('b:VCSCommandBufferInfo') && len(b:VCSCommandBufferInfo) != 0
            return g:cool_symbols.branch.' '.b:VCSCommandBufferInfo[0]
        endif
    endif
    return ''
endfunction

function! coolstatusline#GetBranch()
    if winwidth(0) < 75
        return ''
    endif

    return s:GetBranchFromVCSCommand()
endfunction

function! coolstatusline#GetFileType()
    if winwidth(0) - len(&filetype) < 80
        return ''
    endif

    return &filetype

endfunction

function! coolstatusline#GetFileFormat()
    if winwidth(0) < 90
        return ''
    endif

    return &fileformat

endfunction

function! coolstatusline#GetHunks()
    if winwidth(0) < 70
        return ''
    endif

    if s:has_signify && sy#buffer_is_active()
        let hunks = sy#repo#get_stats()
    elseif s:has_gitgutter
        let hunks = GitGutterGetHunkSummary()
    else
        let hunks = ''
    endif

    if len(hunks) != 3
        return ''
    else
        let hunk_symbols = ['+', '~', '-']
        let result = ''

        for i in [0, 1, 2]
            if hunks[i] != 0
                let result .= hunk_symbols[i].hunks[i]
                if i < 2 && hunks[i+1] != 0
                    let result .= ' '
                endif
            endif
        endfor

        return result
    endif
endfunction

function! coolstatusline#GetRuler()
    return "%2.p%% ".g:cool_symbols.lineno." %2.l/%L".g:cool_symbols.line." : %2.c "
endfunction

function! coolstatusline#GetSection(name)
    return coolstatusline#Get{a:name}()
endfunction

function! s:GetSymbols()
    if g:coolstatusline_use_symbols
        return {
            \     'branch'    : '',
            \     'left_sep'  : '',
            \     'right_sep' : '',
            \     'line'      : '☰',
            \     'lineno'    : ''
            \ }
    else
        return {
            \     'branch'    : '',
            \     'left_sep'  : '',
            \     'right_sep' : '',
            \     'line'      : '',
            \     'lineno'    : ''
            \ }
    endif
endfunction

let g:cool_symbols = s:GetSymbols()

function! coolstatusline#TestWidth()
    if winwidth(0) < 100
        return "BYE"
    else
        return "HELLO"
    endif
endfunction

function! s:SetStatusLine()
    call s:SetStatusHighlightGroups()

    "-------------------------------------------------------------------"
    "   %5   >     %3       >         %1         <     %3     <   %5    "
    "-------------------------------------------------------------------"
    " Mode   > Hunks Branch > Filename  Filetype < Fileformat < Ruler "
    "-------------------------------------------------------------------"

    " For explanation of the format expressions see :help statusline

    let &stl.="%5* "
    let &stl.="%{coolstatusline#GetSection('Mode')} "

    let &stl.="%4*".g:cool_symbols.left_sep."%3* "

    let &stl.="%(%{coolstatusline#GetSection('Hunks')} %)"
    let &stl.="%(%{coolstatusline#GetSection('Branch')} %)"

    let &stl.="%2*".g:cool_symbols.left_sep."%1* "

    let &stl.="%t%([%R%M]%) "

    let &stl.="%="

    let &stl.="%(%{(&ro!=0?'[readonly]':'')} %)"
    let &stl.="%(%{coolstatusline#GetSection('FileType')} %)"

    let &stl.="%2*".g:cool_symbols.right_sep."%3* "

    let &stl.="%(%{coolstatusline#GetSection('FileFormat')} %)"

    let &stl.="%4*".g:cool_symbols.right_sep."%5* "

    let &stl.=coolstatusline#GetSection('Ruler')
endfunction

function! coolstatusline#Refresh()
    call s:SetStatusHighlightGroups()
endfunction

augroup status_line
    autocmd!
    autocmd ColorScheme,VimEnter * call s:SetStatusLine()
augroup END
