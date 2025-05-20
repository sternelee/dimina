import { appTasks } from '@ohos/hvigor-ohos-plugin';
import { hvigor } from '@ohos/hvigor';
import fs from 'fs';
import path from 'path';

// Paths configuration
const SHARED_JSAPP_PATH = path.resolve(__dirname, '../shared/jsapp');
const HARMONY_JSAPP_PATH = path.resolve(__dirname, './entry/src/main/resources/rawfile/jsapp');

// JSSDK paths
const SHARED_JSSDK_PATH = path.resolve(__dirname, '../shared/jssdk');
const HARMONY_JSSDK_PATH = path.resolve(__dirname, './dimina/src/main/resources/rawfile/jssdk');

// Function to clean directory except .gitkeep
function cleanDirectoryExceptGitkeep(directory: string) {
    if (fs.existsSync(directory)) {
        const items = fs.readdirSync(directory);
        for (const item of items) {
            if (item !== '.gitkeep') {
                const itemPath = path.join(directory, item);
                const stat = fs.statSync(itemPath);
                if (stat.isDirectory()) {
                    // Remove directory recursively
                    fs.rmSync(itemPath, { recursive: true, force: true });
                } else {
                    // Remove file
                    fs.unlinkSync(itemPath);
                }
            }
        }
    } else {
        fs.mkdirSync(directory, { recursive: true });
    }
}

// Copy function to recursively copy directories
function copyDirectory(source: string, destination: string) {
    // Clean destination directory except .gitkeep before copying
    cleanDirectoryExceptGitkeep(destination);

    // Read all items in the source directory
    const items = fs.readdirSync(source);

    // Copy each item
    for (const item of items) {
        const sourcePath = path.join(source, item);
        const destPath = path.join(destination, item);

        // Check if item is a directory or file
        const stat = fs.statSync(sourcePath);

        if (stat.isDirectory()) {
            // Recursively copy subdirectories
            copyDirectory(sourcePath, destPath);
        } else {
            // Copy files
            fs.copyFileSync(sourcePath, destPath);
        }
    }
}

hvigor.nodesEvaluated(hvigorNode => {
    try {
        // Ensure parent directories exist
        if (!fs.existsSync(HARMONY_JSAPP_PATH)) {
            fs.mkdirSync(path.dirname(HARMONY_JSAPP_PATH), { recursive: true });
        }
        if (!fs.existsSync(HARMONY_JSSDK_PATH)) {
            fs.mkdirSync(path.dirname(HARMONY_JSSDK_PATH), { recursive: true });
        }

        // Copy jsapp files
        console.log(`Copying shared jsapp files from ${SHARED_JSAPP_PATH} to ${HARMONY_JSAPP_PATH}`);
        copyDirectory(SHARED_JSAPP_PATH, HARMONY_JSAPP_PATH);
        console.log('jsapp files copy completed successfully');

        // Copy jssdk files
        console.log(`Copying shared jssdk files from ${SHARED_JSSDK_PATH} to ${HARMONY_JSSDK_PATH}`);
        copyDirectory(SHARED_JSSDK_PATH, HARMONY_JSSDK_PATH);
        console.log('jssdk files copy completed successfully');
    } catch (error) {
        console.error('Error copying shared files:', error);
    }
})


export default {
    system: appTasks,  /* Built-in plugin of Hvigor. It cannot be modified. */
    plugins:[]         /* Custom plugin to extend the functionality of Hvigor. */
}
