const fs = require('fs');

let html = fs.readFileSync('app.html', 'utf8');

// 1. Replace sidebar AI INTELLIGENCE section
const navRegex = /<span class="sidebar-category-header">AI INTELLIGENCE<\/span>[\s\S]*?<span class="sidebar-category-header">COLLABORATION<\/span>/;
const newNav = `<span class="sidebar-category-header">AI INTELLIGENCE</span>
        <button class="menu-item" data-nav="search">
          <i class="ri-search-eye-line"></i> <span>AI Meeting Search</span>
        </button>
        <button class="menu-item" data-nav="compare">
          <i class="ri-scales-3-line"></i> <span>Meeting Comparison</span>
        </button>
        <button class="menu-item" data-nav="memory">
          <i class="ri-brain-line"></i> <span>Meeting Memory</span>
        </button>
        <button class="menu-item" data-nav="knowledge-base">
          <i class="ri-book-read-line"></i> <span>Company Knowledge</span>
        </button>
        <button class="menu-item" data-nav="chat">
          <i class="ri-sparkling-2-line"></i> <span>Knowledge AI Chat</span>
        </button>
        <button class="menu-item" data-nav="knowledge">
          <i class="ri-links-line"></i> <span>Source Import</span>
        </button>
        <button class="menu-item" data-nav="documents">
          <i class="ri-file-text-line"></i> <span>Documents Vault</span>
        </button>

        <span class="sidebar-category-header">COLLABORATION</span>`;

html = html.replace(navRegex, newNav);

// 2. Replace chat header and add chatScopeBar in #page-chat
const chatHeaderRegex = /<div class="chat-header-bar">[\s\S]*?<\/div>\s*<div class="chat-conversation-area"/;
const newChatHeader = `<div class="chat-header-bar">
              <div class="ai-avatar-glow"><i class="ri-sparkling-fill"></i></div>
              <div>
                <h3 class="chat-title">Ask Your Company Knowledge — Universal AI Chat</h3>
                <p class="chat-sub">Multi-source RAG query across meetings and uploaded documents with grounded citations.</p>
              </div>
              <button class="btn-secondary" id="btnClearChatHistory" style="margin-left: auto;">
                <i class="ri-delete-bin-line"></i> Clear Chat
              </button>
            </div>

            <!-- Scope & Language Switcher Bar -->
            <div class="chat-scope-bar" id="chatScopeBar">
              <div class="scope-chips-group" id="chatScopeChips">
                <button class="scope-chip active" data-scope="all"><i class="ri-global-line"></i> All Sources (Universal)</button>
                <button class="scope-chip" data-scope="meetings"><i class="ri-mic-line"></i> My Meetings Only</button>
                <button class="scope-chip" data-scope="knowledge"><i class="ri-book-read-line"></i> Company Knowledge Only</button>
              </div>
              <div class="lang-btn-group" id="chatLangGroup">
                <button class="btn-lang-toggle active" data-lang="en">English</button>
                <button class="btn-lang-toggle" data-lang="ur">اردو</button>
                <button class="btn-lang-toggle" data-lang="roman">Roman</button>
              </div>
            </div>

            <div class="chat-conversation-area"`;

html = html.replace(chatHeaderRegex, newChatHeader);

fs.writeFileSync('app.html', html, 'utf8');
console.log('Successfully updated app.html with navigation and chatScopeBar!');

