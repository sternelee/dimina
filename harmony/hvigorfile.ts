import { appTasks } from '@ohos/hvigor-ohos-plugin';
import { hvigor } from '@ohos/hvigor';
import fs from 'fs';
import path from 'path';

// Paths configuration
const SHARED_JSAPP_PATH = path.resolve(__dirname, '../shared/jsapp');
const HARMONY_RAWFILE_PATH = path.resolve(__dirname, './entry/src/main/resources/rawfile/jsapp');

// Create destination directory if it doesn't exist
if (!fs.existsSync(HARMONY_RAWFILE_PATH)) {
    fs.mkdirSync(HARMONY_RAWFILE_PATH, { recursive: true });
}

// Copy function to recursively copy directories
function copyDirectory(source, destination) {
    // Create destination directory if it doesn't exist
    if (!fs.existsSync(destination)) {
        fs.mkdirSync(destination, { recursive: true });
    }

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
        console.log(`Copying shared jsapp files from ${SHARED_JSAPP_PATH} to ${HARMONY_RAWFILE_PATH}`);
        copyDirectory(SHARED_JSAPP_PATH, HARMONY_RAWFILE_PATH);
        console.log('Copy completed successfully');
    } catch (error) {
        console.error('Error copying shared jsapp files:', error);
    }
})


export default {
    system: appTasks,  /* Built-in plugin of Hvigor. It cannot be modified. */
    plugins:[]         /* Custom plugin to extend the functionality of Hvigor. */
}
