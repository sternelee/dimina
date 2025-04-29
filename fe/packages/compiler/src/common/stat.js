import fs from 'node:fs'
import path from 'node:path'
import * as cheerio from 'cheerio'

const tagList = new Set([
	'cover-image',
	'cover-view',
	'match-media',
	'movable-area',
	'movable-view',
	'root-portal',
	'scroll-view',
	'swiper',
	'swiper-item',
	'view',
	'icon',
	'text',
	'progress',
	'rich-text',
	'button',
	'checkbox',
	'checkbox-group',
	'editor',
	'form',
	'input',
	'keyboard-accessory',
	'label',
	'picker',
	'picker-view',
	'picker-view-column',
	'radio',
	'radio-group',
	'slider',
	'switch',
	'textarea',
	'navigator',
	'audio',
	'camera',
	'image',
	'video',
	'map',
	'canvas',
	'ad',
	'ad-custom',
	'official-account',
	'open-data',
	'web-view',
	'navigation-bar',
	'page-meta',
])

// 用来存储所有遇到的HTML标签
const tags = new Set()

// 递归读取指定文件夹下的所有.html文件
function readDirRecursive(dir, ext) {
	fs.readdirSync(dir).forEach((file) => {
		const filePath = path.join(dir, file)
		const stat = fs.statSync(filePath)
		if (stat.isDirectory()) {
			readDirRecursive(filePath, ext)
		}
		else if (filePath.endsWith(ext)) {
			const html = fs.readFileSync(filePath, 'utf8')
			readHtmlFile(html)
			parseHtmlForWxMethods(html)
		}
	})
}

// 读取一个HTML文件并统计其中的标签
function readHtmlFile(htmlContent) {
	const $ = cheerio.load(htmlContent)
	$('*').each((_, elem) => {
		tags.add(elem.name)
	})
}

// 存储wx.开头的方法名的集合
const wxMethods = new Set()

// 查找wx.开头的方法
function parseHtmlForWxMethods(htmlContent) {
	const scriptRegex = /<script>([\s\S]*?)<\/script>/g
	let match
	while ((match = scriptRegex.exec(htmlContent)) !== null) {
		const scriptContent = match[1]
		const methodRegex = /\b(wx\.|dd\.|mpx\.)[\w$]+\b/g
		let wxMatch
		while ((wxMatch = methodRegex.exec(scriptContent)) !== null) {
			const methodName = wxMatch[0]
			wxMethods.add(methodName)
		}
	}
}

// 开始读取指定的文件夹
const directory = '' // 替换为你的文件夹路径
readDirRecursive(directory, '.mpx')

const intersection = new Set()
for (const tag of tags) {
	if (tagList.has(tag)) {
		intersection.add(tag)
	}
}

const sortedTags = Array.from(intersection).sort()
const sortedMethods = Array.from(wxMethods).sort()
// 输出统计结果
console.log('所有遇到的HTML标签：', sortedTags)
console.log('所有遇到的JS方法：', sortedMethods)
fs.writeFileSync('tags.txt', `${sortedMethods.join('\n')}\n`)
