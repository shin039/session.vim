" session
" Author: skanehira
" License: MIT

" ------------------------------------------------------------------------------
"  Define
" ------------------------------------------------------------------------------
" buffer name
let s:session_list_buffer = 'SESSIONS_TMP'
" path separator
let s:sep = fnamemodify('.', ':p')[-1:]

if exists('*readdir')
  let s:readdir = function('readdir')
else
  function! s:readdir(dir) abort
    return map(glob(a:dir . s:sep . '*', 1, 1), 'fnamemodify(v:val, ":t")')
  endfunction
endif

" ------------------------------------------------------------------------------
" Functions
" ------------------------------------------------------------------------------
" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
" Utility
" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
function! s:echo_err(msg) abort
  echohl ErrorMsg
  echomsg 'session.vim:' a:msg
  echohl None
endfunction

function! s:files() abort
  let session_path = get(g:, 'session_path', '')
  if session_path is# ''
    call s:echo_err('session_path is empty')
    return []
  endif

  let session_path = expand(session_path)
  let Filter = { _, file -> !isdirectory(session_path . s:sep . file) }
  return filter(s:readdir(session_path), Filter)
endfunction

" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
" Session List
" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
function! session#sessions() abort
  let files = s:files()
  if empty(files)
    return
  endif

  " if buffer exists
  if bufexists(s:session_list_buffer)
    " if buffer display in window
    let winid = bufwinid(s:session_list_buffer)
    if winid isnot# -1
      call win_gotoid(winid)
    else
      execute 'vertical sbuffer' s:session_list_buffer
    endif
  else
    execute 'vertical new' s:session_list_buffer
    set buftype=nofile

    " <silent> コマンドラインへの表示なし
    " <buffer> カレントバッファのみで使用できるmap
    nnoremap <silent> <buffer>
          \   <Plug>(session-close)
          \   :<C-u>bwipeout!<CR>
    nnoremap <silent> <buffer>
          \   <Plug>(session-open)
          \   :<C-u>call session#load_session(trim(getline('.')))<CR>
    nnoremap <silent> <buffer>
          \   <Plug>(session-delete)
          \   :<C-u>call session#delete_session(trim(getline('.')))<CR>

    nmap <buffer> q    <Plug>(session-close)
    nmap <buffer> e    <Plug>(session-close)
    nmap <buffer> o    <Plug>(session-open)
    nmap <buffer> <CR> <Plug>(session-open)
    nmap <buffer> d    <Plug>(session-delete)
  endif

  " delete buffer contents
  %delete _
  call setline(1, files)
endfunction

" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
" Session Delete
" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
function! session#delete_session(file) abort
  let delfile = join([g:session_path, a:file], s:sep)
  try
    call delete(expand(delfile))
  catch
    echo "session.vim: File Delete Err " .. v:exception
  endtry

  call session#sessions()
  redraw
  echo 'session.vim: deleted =>' a:file
endfunction

" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
" Session Create
" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
function! session#create_session(file) abort
  execute 'mksession!' join([g:session_path, a:file], s:sep)
  redraw
  echo 'session.vim: created => ' a:file
endfunction

" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
" Session Load
" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
function! session#load_session(file) abort
  execute 'source' join([g:session_path, a:file], s:sep)

  if bufexists(s:session_list_buffer)
    execute 'bwipeout!' s:session_list_buffer 
  endif

endfunction
