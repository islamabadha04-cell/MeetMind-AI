const fs = require('fs');

let code = fs.readFileSync('app.js', 'utf8');

const targetOldChatFuncRegex = /function handleDeskAiChat\(promptText\) \{[\s\S]*?\}, 450\);\s*\}/;

const newChatFunc = `function handleDeskAiChat(promptText) {
  executeUniversalRagChat(promptText);
}`;

code = code.replace(targetOldChatFuncRegex, newChatFunc);

fs.writeFileSync('app.js', code, 'utf8');
console.log('Successfully updated handleDeskAiChat in app.js!');
