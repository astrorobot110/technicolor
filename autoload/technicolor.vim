scriptencoding utf-8

let s:save_cpo = &cpoptions
set cpo&vim

" グローバル変数 {{{

" ctermパレットからRGB値への変換用
let s:rgbValue = ['00', '5f', '87', 'af', 'd7', 'ff']

let s:gray2color = {
		\ '95'	: 59,
		\ '135'	: 102,
		\ '175'	: 145,
		\ '215'	: 188
		\ }

" vimが解釈する色名のリスト
let s:colorName = {
		\ 'none'			: '',
		\ 'bg'				: '',
		\ 'BackGround'		: '',
		\ 'fg'				: '',
		\ 'ForeGround'		: '',
		\ 'Black'			: '',
		\ 'DarkRed'			: '',
		\ 'DarkGreen'		: '',
		\ 'DarkYellow'		: '',
		\ 'Brown'			: '',
		\ 'DarkBlue'		: '',
		\ 'DarkMagenta'		: '',
		\ 'DarkCyan'		: '',
		\ 'Gray'			: '',
		\ 'Grey'			: '',
		\ 'DarkGray'		: '',
		\ 'DarkGrey'		: '',
		\ 'Red'				: '',
		\ 'Green'			: '',
		\ 'Yellow'			: '',
		\ 'Blue'			: '',
		\ 'Magenta'			: '',
		\ 'Cyan'			: '',
		\ 'White'			: '',
		\ 'LightGray'		: '',
		\ 'LightGrey'		: '',
		\ 'LightRed'		: '',
		\ 'LightGreen'		: '',
		\ 'LightYellow'		: '',
		\ 'LightBlue'		: '',
		\ 'LightMagenta'	: '',
		\ 'LightCyan'		: '',
		\ 'orange'			: 214,
		\ 'purple'			: 129,
		\ 'violet'			: 213,
		\ 'seagreen'		: 29,
		\ 'slateblue'		: 62
		\ }

" }}}

function! s:rgb2cterm(rgbList) abort " RGB値からctermへ変換 {{{
	for value in a:rgbList
		let term = get(l:, 'term', 0)*6
		if value >= 75
			let term += ((value-75)/40)+1
		endif
	endfor

	return term+16
endfunction " }}}

function! s:gray2cterm(level) abort " RGB値がグレーになる場合 {{{
	if a:level <= 3
		return 16
	elseif a:level >= 243
		return 231
	elseif has_key(s:gray2color, a:level)
		return s:gray2color[a:level]
	endif

	let step = sort([0, (a:level-3)/10, 23], 'n')[1]

	return step+232
endfunction " }}}

function! s:term2sysRgb(term) abort " xtermシステムカラーからRGB値へ変換 {{{
	if a:term == 7
		return '#c0c0c0'
	elseif a:term == 8
		return '#808080'
	elseif a:term < 7
		let value = '80'
	else
		let value = 'ff'
	endif

	let rgb = '#'

	for div in [1, 2, 4]
		let rgb .= (a:term/div)%2 == 0 ? '00' : value
	endfor

	return rgb
endfunction " }}}

function! s:term2gray(term) abort " xtermパレットのグレースケールからRGB値へ変換 {{{
	let rgb = printf('%02x', a:term*10+8)
	return '#'..repeat(rgb, 3)
endfunction
" }}}

function! s:term2rgb(term) abort " xtermカラーパレットからRGB値へ変換 {{{
	if a:term <= 15
		return s:term2sysRgb(a:term)

	elseif a:term >= 232
		return s:term2gray(a:term-232)

	else
		let term = a:term-16
		let rgb = '#'

		for div in [36, 6, 1]
			let rgb .= s:rgbValue[(term/div)%6]
		endfor

		return rgb
	endif
endfunction " }}}

function! s:gui2cterm(value) abort " guiからctermへ変換 {{{
	if match(keys(s:colorName), '\c^'..a:value..'$') > 0
		if s:colorName[a:value] ==# ''
			return a:value
		else
			return s:colorName[a:value]
		endif
	elseif a:value =~? '^#\?\x\{6}$'
		let rgbList = matchlist(a:value, '\v^#(\x\x)(\x\x)(\x\x)')[1:3]
				\ ->map({_, val ->str2nr(val, 16)})

		if len(uniq(copy(rgbList))) == 1
			return s:gray2cterm(rgbList[0])
		endif

		return s:rgb2cterm(rgbList)
	endif

	return 'none'
endfunction " }}}

function! s:cterm2gui(value) abort " ctermからguiへ変換 {{{
	if match(keys(s:colorName), '\c^'..a:value..'$') > 0
		if s:colorName[a:value] ==# ''
			return a:value
		else
			return s:colorName[a:value]
		endif
	elseif sort([0, a:value, 255], 'n')[1] == a:value
		return s:term2rgb(a:value)

	endif

	return 'none'
endfunction " }}}

" クラス定義 {{{
let s:Technicolor = {
		\	'case':		0,
		\	'command':	'highlight',
		\	'ctermfg':	'',
		\	'ctermbg':	'',
		\	'cterm':	'',
		\	'guifg':	'',
		\	'guibg':	'',
		\	'gui':		'',
		\	'order':	[ 'ctermfg', 'ctermbg', 'cterm', 'guifg', 'guibg', 'gui' ],
		\ }
" }}}

function! s:Technicolor.fetch(key) abort " クラス内: 値の変換 {{{
	let [ env, ground ] = matchlist(a:key, '\v^(cterm|gui)(fg|bg)?')[1:2]
	let target = env ==? 'cterm' ? 'gui' : 'cterm'
	let targetKey = target..ground

	if ground ==# ''
		let value = self[targetKey]
		let self[env..ground] = value
	else
		let value = function(printf('s:%s2%s', target, env))(self[targetKey])
		let self[env..ground] = value
	endif
endfunction " }}}

function! technicolor#get(...) abort " 値の取得 {{{
	if a:0 == 0
		let line = getline('.')

	elseif str2nr(a:1) > 0
		let line = getline(a:1)

	elseif a:1 ==# 'template'
		let template = 1

	elseif a:1 ==# 'top'
		while !exists('line')
			let index = get(l:, 'index', 1)
			let line = matchstr(getline(1, '$'), '\v^\s*("\s*)?hi(ghlight)?\!?.*$', 0, index)

			if match(line, '\c\(clear\|link\)') > -1
				unlet line
			endif

			let index += 1
		endwhile

	else
		let line = matchstr(getline(1, '$'), '\v^\s*("\s*)?hi(ghlight)?\!?\s+'..a:1..'.*$')

	endif

	let template = get(l:, 'template',
			\ get(a:, '2', '') ==# 'template' ? 1 : 0 )

	let list = split(line, '\s\+')

	let technicolor = deepcopy(s:Technicolor)
	if template
		let technicolor.order = []
	endif

	for arg in list
		if arg =~# 'hi\(ghlight\)\?'
			let technicolor.command = arg

		elseif arg =~# '\v(cterm|gui)(fg|bg)?\=\S+'
			let [ key, value ] = split(arg, '=')
			let technicolor[key] = value

			if !technicolor.case && value[0] ==# '#'
				let technicolor.case = value =~# '\u'
			endif

			if template
				call add(technicolor.order, key)
			endif
		endif
	endfor

	return technicolor
endfunction " }}}

function! technicolor#main() abort " main {{{
	let b:technicolor_headLine = get(b:, 'technicolor_headLine',
			\ get(g:, 'technicolor_headLine', 'Normal'))
	let b:technicolor = technicolor#get()
	let b:technicolor.order = technicolor#get(b:technicolor_headLine, 'template').order

	let column = getcurpos()[2]-(mode() =~# 'n')
	let line = getline('.')

	let lastArg = matchlist(line[0:column-1], '\v(%(cterm|gui)%(fg|bg)?)\=(\S+\s*)?$')
	echo lastArg

	if len(lastArg) > 0
		if len(lastArg[2]) > 0
			return b:technicolor.order[match(b:technicolor.order, '^'..lastArg[1]..'$')+1]..'='
		else
			call b:technicolor.fetch(lastArg[1])
			return b:technicolor[lastArg[1]]
		endif
	endif

	return ''
endfunction " }}}

let &cpoptions = s:save_cpo

" vim: set fdm=marker:
