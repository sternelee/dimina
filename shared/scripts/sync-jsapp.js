/**
 * Dimina Shared Assets Synchronization Tool
 * 
 * This script helps manage and synchronize shared assets (jsapp and jssdk) between the shared directory
 * and platform-specific directories. It can be used to:
 * 
 * 1. Import existing assets from Android or Harmony to the shared directory
 * 2. Validate that all platforms have the same assets
 * 3. Clean up platform-specific asset directories
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Path configuration
const ROOT_DIR = path.resolve(__dirname, '..');

// jsapp paths
const SHARED_JSAPP_DIR = path.resolve(ROOT_DIR, 'jsapp');
const ANDROID_JSAPP_DIR = path.resolve(ROOT_DIR, '../android/app/src/main/assets/jsapp');
const HARMONY_JSAPP_DIR = path.resolve(ROOT_DIR, '../harmony/entry/src/main/resources/rawfile/jsapp');

// jssdk paths
const SHARED_JSSDK_DIR = path.resolve(ROOT_DIR, 'jssdk');
const ANDROID_JSSDK_DIR = path.resolve(ROOT_DIR, '../android/dimina/src/main/assets/jssdk');
const HARMONY_JSSDK_DIR = path.resolve(ROOT_DIR, '../harmony/dimina/src/main/resources/rawfile/jssdk');

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

// Import assets from platform to shared directory
function importJsappFromPlatform(platformDir) {
  if (!fs.existsSync(platformDir)) {
    console.error(`Platform directory does not exist: ${platformDir}`);
    return;
  }
  
  console.log(`Importing jsapp files from ${platformDir} to ${SHARED_JSAPP_DIR}`);
  copyDirectory(platformDir, SHARED_JSAPP_DIR);
  console.log('jsapp import completed');
}

// Import jssdk files from platform to shared directory
function importJssdkFromPlatform(platformDir) {
  if (!fs.existsSync(platformDir)) {
    console.error(`Platform directory does not exist: ${platformDir}`);
    return;
  }
  
  console.log(`Importing jssdk files from ${platformDir} to ${SHARED_JSSDK_DIR}`);
  copyDirectory(platformDir, SHARED_JSSDK_DIR);
  console.log('jssdk import completed');
}

// Validate that all platforms have the same jsapp files
function validateJsappSync() {
  const platforms = [
    { name: 'Android', dir: ANDROID_JSAPP_DIR },
    { name: 'Harmony', dir: HARMONY_JSAPP_DIR }
  ];
  
  let hasErrors = false;
  
  // Check if shared directory exists
  if (!fs.existsSync(SHARED_JSAPP_DIR)) {
    console.error(`Shared jsapp directory does not exist: ${SHARED_JSAPP_DIR}`);
    return hasErrors;
  }
  
  // Get list of apps in shared directory
  const sharedApps = fs.existsSync(SHARED_JSAPP_DIR) ? 
    fs.readdirSync(SHARED_JSAPP_DIR).filter(item => 
      fs.statSync(path.join(SHARED_JSAPP_DIR, item)).isDirectory()
    ) : [];
  
  if (sharedApps.length === 0) {
    console.log('No apps found in shared jsapp directory');
    return hasErrors;
  }
  
  console.log(`Found ${sharedApps.length} apps in shared jsapp directory: ${sharedApps.join(', ')}`);
  
  // Check each platform
  for (const platform of platforms) {
    console.log(`\nChecking ${platform.name} jsapp platform...`);
    
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
  
  return hasErrors;
}

// Validate that all platforms have the same jssdk files
function validateJssdkSync() {
  const platforms = [
    { name: 'Android', dir: ANDROID_JSSDK_DIR },
    { name: 'Harmony', dir: HARMONY_JSSDK_DIR }
  ];
  
  let hasErrors = false;
  
  // Check if shared directory exists
  if (!fs.existsSync(SHARED_JSSDK_DIR)) {
    console.error(`Shared jssdk directory does not exist: ${SHARED_JSSDK_DIR}`);
    return hasErrors;
  }
  
  // Get list of files in shared directory
  const sharedFiles = fs.existsSync(SHARED_JSSDK_DIR) ? 
    fs.readdirSync(SHARED_JSSDK_DIR) : [];
  
  if (sharedFiles.length === 0) {
    console.log('No files found in shared jssdk directory');
    return hasErrors;
  }
  
  console.log(`Found ${sharedFiles.length} files in shared jssdk directory: ${sharedFiles.join(', ')}`);
  
  // Check each platform
  for (const platform of platforms) {
    console.log(`\nChecking ${platform.name} jssdk platform...`);
    
    if (!fs.existsSync(platform.dir)) {
      console.log(`${platform.name} jssdk directory does not exist: ${platform.dir}`);
      continue;
    }
    
    const platformFiles = fs.readdirSync(platform.dir);
    
    // Check for missing files
    const missingFiles = sharedFiles.filter(file => !platformFiles.includes(file));
    if (missingFiles.length > 0) {
      console.error(`${platform.name} jssdk is missing files: ${missingFiles.join(', ')}`);
      hasErrors = true;
    }
    
    // Check for extra files
    const extraFiles = platformFiles.filter(file => !sharedFiles.includes(file) && file !== '.keep');
    if (extraFiles.length > 0) {
      console.warn(`${platform.name} jssdk has extra files not in shared directory: ${extraFiles.join(', ')}`);
    }
    
    // Check file content
    for (const file of sharedFiles) {
      if (!platformFiles.includes(file)) continue;
      
      const sharedFilePath = path.join(SHARED_JSSDK_DIR, file);
      const platformFilePath = path.join(platform.dir, file);
      
      const sharedStat = fs.statSync(sharedFilePath);
      const platformStat = fs.statSync(platformFilePath);
      
      if (sharedStat.size !== platformStat.size) {
        console.error(`File size mismatch for jssdk/${file}: shared=${sharedStat.size}, ${platform.name}=${platformStat.size}`);
        hasErrors = true;
      }
    }
  }
  
  return hasErrors;
}

// Validate that all platforms have the same assets
function validateSync() {
  console.log('Validating jsapp synchronization...');
  const jsappErrors = validateJsappSync();
  
  console.log('\nValidating jssdk synchronization...');
  const jssdkErrors = validateJssdkSync();
  
  if (!jsappErrors && !jssdkErrors) {
    console.log('\n✅ All platforms are in sync with shared directories');
  } else {
    console.error('\n❌ Found sync issues. Run sync command to fix.');
  }
}

// Clean up platform-specific asset directories
function cleanPlatforms() {
  const jsappPlatforms = [
    { name: 'Android jsapp', dir: ANDROID_JSAPP_DIR },
    { name: 'Harmony jsapp', dir: HARMONY_JSAPP_DIR }
  ];
  
  const jssdkPlatforms = [
    { name: 'Android jssdk', dir: ANDROID_JSSDK_DIR },
    { name: 'Harmony jssdk', dir: HARMONY_JSSDK_DIR }
  ];
  
  // Clean jsapp directories
  for (const platform of jsappPlatforms) {
    if (fs.existsSync(platform.dir)) {
      console.log(`Cleaning ${platform.name} directory: ${platform.dir}`);
      fs.rmSync(platform.dir, { recursive: true, force: true });
      console.log(`${platform.name} directory cleaned`);
    }
  }
  
  // Clean jssdk directories
  for (const platform of jssdkPlatforms) {
    if (fs.existsSync(platform.dir)) {
      console.log(`Cleaning ${platform.name} directory: ${platform.dir}`);
      fs.rmSync(platform.dir, { recursive: true, force: true });
      console.log(`${platform.name} directory cleaned`);
    }
  }
}

// Parse command line arguments
function main() {
  const args = process.argv.slice(2);
  const command = args[0];
  
  // Ensure shared directories exist
  ensureDirectoryExists(SHARED_JSAPP_DIR);
  ensureDirectoryExists(SHARED_JSSDK_DIR);
  
  switch (command) {
    case 'import-android-jsapp':
      importJsappFromPlatform(ANDROID_JSAPP_DIR);
      break;
    case 'import-harmony-jsapp':
      importJsappFromPlatform(HARMONY_JSAPP_DIR);
      break;
    case 'import-android-jssdk':
      importJssdkFromPlatform(ANDROID_JSSDK_DIR);
      break;
    case 'import-harmony-jssdk':
      importJssdkFromPlatform(HARMONY_JSSDK_DIR);
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
  import-android-jsapp    Import jsapp files from Android to shared directory
  import-harmony-jsapp    Import jsapp files from Harmony to shared directory
  import-android-jssdk    Import jssdk files from Android to shared directory
  import-harmony-jssdk    Import jssdk files from Harmony to shared directory
  validate                Validate that all platforms have the same assets
  clean                   Clean up platform-specific asset directories
  sync                    Clean platforms and prepare for sync from shared directory
      `);
  }
}

main();
