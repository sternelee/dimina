#!/usr/bin/env node

const fs = require('node:fs')
const path = require('node:path')
const { execSync } = require('node:child_process')
const process = require('node:process')

// Define paths
const publicPath = path.resolve(__dirname, '../packages/container/public')
const sharedJsappPath = path.resolve(__dirname, '../../shared/jsapp')

// Check if the shared/jsapp directory exists
if (!fs.existsSync(sharedJsappPath)) {
	console.error(`Error: Directory ${sharedJsappPath} does not exist.`)
	console.error('Please create the directory first before running this command.')
	process.exit(1) // Terminate the script with error code
}

// Get all app directories from public
const appDirs = fs.readdirSync(publicPath)
	.filter((item) => {
		const itemPath = path.join(publicPath, item)
		return fs.statSync(itemPath).isDirectory() && (item.startsWith('wx') || item.startsWith('dd'))
	})

console.log('Found app directories:', appDirs)

// Process each app directory
appDirs.forEach((appId) => {
	const appPublicPath = path.join(publicPath, appId)
	const appSharedPath = path.join(sharedJsappPath, appId)

	// Create app directory in shared/jsapp if it doesn't exist
	if (!fs.existsSync(appSharedPath)) {
		fs.mkdirSync(appSharedPath, { recursive: true })
	}

	// Check if config.json exists in shared/jsapp
	const configPath = path.join(appSharedPath, 'config.json')
	let config = {
		appId,
		name: `App ${appId}`,
		path: 'example/index',
		versionCode: 1,
		versionName: '1.0.0',
	}

	// If config exists, read it and increment version
	if (fs.existsSync(configPath)) {
		try {
			config = JSON.parse(fs.readFileSync(configPath, 'utf8'))
			config.versionCode += 1

			// Increment the last part of the version name (e.g., 1.0.0 -> 1.0.1)
			const versionParts = config.versionName.split('.')
			versionParts[versionParts.length - 1] = (Number.parseInt(versionParts[versionParts.length - 1]) + 1).toString()
			config.versionName = versionParts.join('.')

			console.log(`Incrementing version for ${appId}: ${config.versionName} (${config.versionCode})`)
		}
		catch (error) {
			console.error(`Error reading or parsing config for ${appId}:`, error)
		}
	}
	else {
		console.log(`Creating new config for ${appId}`)
	}

	// Write updated config
	fs.writeFileSync(configPath, JSON.stringify(config, null, 2), 'utf8')

	// Create zip file from the app directory
	try {
		// Create a temporary directory for the app files
		const tempDir = path.join(__dirname, `../temp-${appId}`)
		if (fs.existsSync(tempDir)) {
			fs.rmSync(tempDir, { recursive: true, force: true })
		}
		fs.mkdirSync(tempDir, { recursive: true })

		// Copy all files from public app directory to temp directory
		execSync(`cp -R ${path.join(appPublicPath, 'main')}/* ${tempDir}`)

		// Create zip file
		const zipPath = path.join(appSharedPath, `${appId}.zip`)
		execSync(`cd ${tempDir} && zip -r ${zipPath} .`)

		// Clean up temp directory
		fs.rmSync(tempDir, { recursive: true, force: true })

		console.log(`Successfully created ${zipPath}`)
	}
	catch (error) {
		console.error(`Error creating zip for ${appId}:`, error)
	}
})

console.log('App generation completed successfully!')
