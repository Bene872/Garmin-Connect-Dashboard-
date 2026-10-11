import {copyFileSync,mkdirSync} from 'node:fs';
mkdirSync('ios/Pulse/Resources',{recursive:true});
copyFileSync('docs/index.html','ios/Pulse/Resources/dashboard.html');
console.log('iPhone dashboard bundled. Native compilation must run with Xcode on macOS.');
