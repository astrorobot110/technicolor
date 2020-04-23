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
		\	'case':			0,
		\	'structure':	0,
		\	'command':		'highlight',
		\	'ctermfg':		'',
		\	'ctermbg':		'',
		\	'cterm':		'',
		\	'guifg':		'',
		\	'guibg':		'',
		\	'gui':			'',
		\	'order':		[ 'ctermfg', 'ctermbg', 'cterm', 'guifg', 'guibg', 'gui' ],
		\	'length':		[ 24, 40, 56, 72, 88, 104, 120 ],
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

function! s:Technicolor.getArgs() abort " 値の取得 {{{
	let line = getline('.')

	if line !~# '\v^\s*("\s*)?hi(ghlight)?'
		throw '[technicolor]: No highlight line.'
	endif

	for key in keys(self)->filter('v:val =~# ''\v(cterm|gui)''')
		let self[key] = ''
	endfor

	let list = split(line, '\s\+')

	for arg in list->filter('v:val =~# ''\v^(cterm|gui)''')
		if arg =~# '\v(cterm|gui)(fg|bg)?\=\S+'
			let [ key, value ] = split(arg, '=')
			let self[key] = value
		endif
	endfor
endfunction " }}}

function! s:Technicolor.getTemplate(...) abort " テンプレートの取得 {{{
	if a:0 == 0
		let line = getline('.')

	elseif str2nr(a:1) > 0
		let line = getline(a:1)

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

	if line !~# '\v^\s*("\s*)?hi(ghlight)?'
		throw '[technicolor]: No highlight line.'
	endif

	let self.case = 0
	let self.structure = 1
	let self.command = 'highlight'
	let self.order = []
	let self.length = []

	let list = split(line, '\s\+\zs')
	let length = ''

	for arg in list
		let lengthFlag = 0

		if arg =~# '^\s*$'
			continue

		elseif arg =~# '\v^hi(ghlight)?'
			let self.command = trim(arg)

		elseif arg =~# '\v^\S+\=\S+'
			let lengthFlag = 1
			if len(self.length) == 0
				call add(self.length, strdisplaywidth(length))
			endif

			call add(self.order, matchstr(arg, '^\S\+\ze='))

			if self.case || arg =~# '\u'
				let self.case = 1
			endif
		endif

		let length .= arg
		if lengthFlag
			call add(self.length, strdisplaywidth(length))
		endif
	endfor

endfunction " }}}

function! technicolor#main(...) abort " main {{{
	let column = getcurpos()[2]-(mode() =~# 'n')
	let line = getline('.')[0:column-1]

	if line !~# '\v^\s*("\s*)?hi(ghlight)?'
		throw '[technicolor]: No highlight line.'
	endif

	if get(a:, '1', 0) || !exists('b:technicolor')
		let b:technicolor = deepcopy(s:Technicolor)
	endif
	call b:technicolor.getArgs()

	let lastArg = matchlist(line, '\v(%(cterm|gui)%(fg|bg)?)\=(\S+)?\s*$')

	if len(lastArg) > 0
		if len(lastArg[2]) > 0
			let index = 0
			let nextArg = ''
			while index < len(b:technicolor.length) && len(nextArg) == 0
				if strdisplaywidth(trim(line)) <= b:technicolor.length[index]
					let nextArg = b:technicolor.order[index]..'='
				endif

				let index += 1
			endwhile

			return nextArg
		else
			call b:technicolor.fetch(lastArg[1])
			return b:technicolor[lastArg[1]]
		endif
	else
		return b:technicolor.order[0]..'='
	endif

	return ''
endfunction " }}}

let &cpoptions = s:save_cpo

" vim: set fdm=marker:
