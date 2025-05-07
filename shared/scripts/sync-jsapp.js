/**
 * Dimina Shared Assets Synchronization Tool
 * 
 * This script helps manage and synchronize jsapp assets between the shared directory
 * and platform-specific directories. It can be used to:
 * 
 * 1. Import existing jsapp files from Android or Harmony to the shared directory
 * 2. Validate that all platforms have the same jsapp files
 * 3. Clean up platform-specific jsapp directories
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Path configuration
const ROOT_DIR = path.resolve(__dirname, '..');
const SHARED_JSAPP_DIR = path.resolve(ROOT_DIR, 'jsapp');
const ANDROID_JSAPP_DIR = path.resolve(ROOT_DIR, '../android/app/src/main/assets/jsapp');
const HARMONY_JSAPP_DIR = path.resolve(ROOT_DIR, '../harmony/dimina/src/main/resources/rawfile/jsapp');

// Ensure directories exist
function ensureDirectoryExists(dir) {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
    console.log(`Created directory: ${dir}`);
  }
}

// Copy directory recursively
function copyDirectory(source, destination) {
  ensureDirectoryExists(destination);
  
  const items = fs.readdirSync(source);
  
  for (const item of items) {
    const sourcePath = path.join(source, item);
    const destPath = path.join(destination, item);
    
    const stat = fs.statSync(sourcePath);
    
    if (stat.isDirectory()) {
      copyDirectory(sourcePath, destPath);
    } else {
      fs.copyFileSync(sourcePath, destPath);
      console.log(`Copied: ${sourcePath} -> ${destPath}`);
    }
  }
}

// Import jsapp files from platform to shared directory
function importFromPlatform(platformDir) {
  if (!fs.existsSync(platformDir)) {
    console.error(`Platform directory does not exist: ${platformDir}`);
    return;
  }
  
  console.log(`Importing jsapp files from ${platformDir} to ${SHARED_JSAPP_DIR}`);
  copyDirectory(platformDir, SHARED_JSAPP_DIR);
  console.log('Import completed');
}

// Validate that all platforms have the same jsapp files
function validateSync() {
  const platforms = [
    { name: 'Android', dir: ANDROID_JSAPP_DIR },
    { name: 'Harmony', dir: HARMONY_JSAPP_DIR }
  ];
  
  let hasErrors = false;
  
  // Check if shared directory exists
  if (!fs.existsSync(SHARED_JSAPP_DIR)) {
    console.error(`Shared jsapp directory does not exist: ${SHARED_JSAPP_DIR}`);
    return;
  }
  
  // Get list of apps in shared directory
  const sharedApps = fs.existsSync(SHARED_JSAPP_DIR) ? 
    fs.readdirSync(SHARED_JSAPP_DIR).filter(item => 
      fs.statSync(path.join(SHARED_JSAPP_DIR, item)).isDirectory()
    ) : [];
  
  if (sharedApps.length === 0) {
    console.log('No apps found in shared directory');
    return;
  }
  
  console.log(`Found ${sharedApps.length} apps in shared directory: ${sharedApps.join(', ')}`);
  
  // Check each platform
  for (const platform of platforms) {
    console.log(`\nChecking ${platform.name} platform...`);
    
    if (!fs.existsSync(platform.dir)) {
      console.log(`${platform.name} jsapp directory does not exist: ${platform.dir}`);
      continue;
    }
    
    const platformApps = fs.readdirSync(platform.dir).filter(item => 
      fs.statSync(path.join(platform.dir, item)).isDirectory()
    );
    
    // Check for missing apps
    const missingApps = sharedApps.filter(app => !platformApps.includes(app));
    if (missingApps.length > 0) {
      console.error(`${platform.name} is missing apps: ${missingApps.join(', ')}`);
      hasErrors = true;
    }
    
    // Check for extra apps
    const extraApps = platformApps.filter(app => !sharedApps.includes(app));
    if (extraApps.length > 0) {
      console.warn(`${platform.name} has extra apps not in shared directory: ${extraApps.join(', ')}`);
    }
    
    // Check file content for each app
    for (const app of sharedApps) {
      if (!platformApps.includes(app)) continue;
      
      const sharedAppDir = path.join(SHARED_JSAPP_DIR, app);
      const platformAppDir = path.join(platform.dir, app);
      
      const sharedFiles = fs.readdirSync(sharedAppDir);
      const platformFiles = fs.readdirSync(platformAppDir);
      
      // Check for missing files
      const missingFiles = sharedFiles.filter(file => !platformFiles.includes(file));
      if (missingFiles.length > 0) {
        console.error(`${platform.name} app ${app} is missing files: ${missingFiles.join(', ')}`);
        hasErrors = true;
      }
      
      // Check file content
      for (const file of sharedFiles) {
        if (!platformFiles.includes(file)) continue;
        
        const sharedFilePath = path.join(sharedAppDir, file);
        const platformFilePath = path.join(platformAppDir, file);
        
        const sharedStat = fs.statSync(sharedFilePath);
        const platformStat = fs.statSync(platformFilePath);
        
        if (sharedStat.size !== platformStat.size) {
          console.error(`File size mismatch for ${app}/${file}: shared=${sharedStat.size}, ${platform.name}=${platformStat.size}`);
          hasErrors = true;
        }
      }
    }
  }
  
  if (!hasErrors) {
    console.log('\n✅ All platforms are in sync with shared directory');
  } else {
    console.error('\n❌ Found sync issues. Run sync command to fix.');
  }
}

// Clean up platform-specific jsapp directories
function cleanPlatforms() {
  const platforms = [
    { name: 'Android', dir: ANDROID_JSAPP_DIR },
    { name: 'Harmony', dir: HARMONY_JSAPP_DIR }
  ];
  
  for (const platform of platforms) {
    if (fs.existsSync(platform.dir)) {
      console.log(`Cleaning ${platform.name} jsapp directory: ${platform.dir}`);
      fs.rmSync(platform.dir, { recursive: true, force: true });
      console.log(`${platform.name} jsapp directory cleaned`);
    }
  }
}

// Parse command line arguments
function main() {
  const args = process.argv.slice(2);
  const command = args[0];
  
  ensureDirectoryExists(SHARED_JSAPP_DIR);
  
  switch (command) {
    case 'import-android':
      importFromPlatform(ANDROID_JSAPP_DIR);
      break;
    case 'import-harmony':
      importFromPlatform(HARMONY_JSAPP_DIR);
      break;
    case 'validate':
      validateSync();
      break;
    case 'clean':
      cleanPlatforms();
      break;
    case 'sync':
      cleanPlatforms();
      console.log('Platforms cleaned, build the projects to sync from shared directory');
      break;
    default:
      console.log(`
Dimina Shared Assets Synchronization Tool

Usage:
  node sync-jsapp.js <command>

Commands:
  import-android   Import jsapp files from Android to shared directory
  import-harmony   Import jsapp files from Harmony to shared directory
  validate         Validate that all platforms have the same jsapp files
  clean            Clean up platform-specific jsapp directories
  sync             Clean platforms and prepare for sync from shared directory
      `);
  }
}

main();
