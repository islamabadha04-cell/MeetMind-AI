const fs = require('fs');

let html = fs.readFileSync('app.html', 'utf8');

// 1. Update Sidebar Nav Items
const oldNavBlock = `<span class="sidebar-category-header">AI INTELLIGENCE</span>
        <button class="menu-item" data-nav="chat">
          <i class="ri-sparkling-2-line"></i> <span>Ask AI Chat</span>
        </button>
        <button class="menu-item" data-nav="knowledge">
          <i class="ri-links-line"></i> <span>Source Import</span>
        </button>
        <button class="menu-item" data-nav="documents">
          <i class="ri-file-text-line"></i> <span>Documents Vault</span>
        </button>`;

const newNavBlock = `<span class="sidebar-category-header">AI INTELLIGENCE</span>
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
        </button>`;

if (html.includes(oldNavBlock)) {
  html = html.replace(oldNavBlock, newNavBlock);
}

// 2. Add Phase 2 Views right before `<!-- ==================== PAGE 5: ASK AI CHAT ==================== -->`
const targetPage5 = '<!-- ==================== PAGE 5: ASK AI CHAT ==================== -->';

const phase2Views = `<!-- ==================== PHASE 2: AI MEETING SEARCH ==================== -->
      <div class="page-view hidden" id="page-search">
        <div class="desktop-content-body">
          <div class="welcome-stats-row">
            <div>
              <h2 class="welcome-title"><i class="ri-search-eye-line" style="color: var(--primary);"></i> AI Meeting Search</h2>
              <p class="welcome-sub">Cross-meeting semantic retrieval across transcripts, executive briefs, decisions, and action items.</p>
            </div>
          </div>

          <div class="search-header-container">
            <div class="search-input-wrap">
              <i class="ri-search-line"></i>
              <input type="text" id="aiMeetingSearchInput" class="search-bar-input" placeholder="Ask or search naturally (e.g. 'Find all meetings where payment delays were discussed')...">
              <button class="btn-primary-purple" id="btnExecuteAiSearch" style="position: absolute; right: 8px; padding: 8px 16px;">
                <i class="ri-sparkling-fill"></i> Search
              </button>
            </div>

            <div class="search-controls-row">
              <div class="search-mode-group" id="searchModeGroup">
                <button class="search-mode-chip active" data-mode="hybrid">Hybrid (Recommended)</button>
                <button class="search-mode-chip" data-mode="semantic">Semantic (Meaning)</button>
                <button class="search-mode-chip" data-mode="keyword">Exact Keyword</button>
              </div>

              <div class="search-filters-group">
                <select class="search-select-filter" id="searchCategoryFilter">
                  <option value="all">All Categories</option>
                  <option value="meetings">Meetings</option>
                  <option value="general">General</option>
                  <option value="sprint">Sprint Review</option>
                </select>

                <select class="search-select-filter" id="searchSpeakerFilter">
                  <option value="all">All Speakers</option>
                  <option value="Emily">Emily Watson / Host</option>
                  <option value="Client">Client / Guest</option>
                </select>

                <select class="search-select-filter" id="searchDateFilter">
                  <option value="all">Any Date</option>
                  <option value="7d">Last 7 Days</option>
                  <option value="30d">Last 30 Days</option>
                </select>
              </div>
            </div>

            <div class="recent-searches-row" id="recentSearchesRow">
              <span style="font-size: 11px; font-weight: 700; color: var(--text-dim); text-transform: uppercase;">Recent Searches:</span>
              <button class="recent-pill" data-query="payment delays">💳 payment delays</button>
              <button class="recent-pill" data-query="project budget">💰 project budget</button>
              <button class="recent-pill" data-query="client complaints">⚠️ client complaints</button>
              <button class="recent-pill" data-query="delivery deadline">📅 delivery deadline</button>
              <button class="recent-pill" data-query="employee performance">🚀 employee performance</button>
            </div>
          </div>

          <!-- AI Search Synthesis Banner -->
          <div class="ai-synthesis-card hidden" id="aiSearchSynthesisBanner">
            <h4 style="font-size: 13.5px; font-weight: 700; color: var(--primary); margin-bottom: 6px; display: flex; align-items: center; gap: 6px;">
              <i class="ri-sparkling-fill"></i> AI Cross-Meeting Synthesis
            </h4>
            <p id="aiSearchSynthesisText" style="font-size: 13.5px; line-height: 1.6; color: var(--text-main);"></p>
          </div>

          <!-- Search Results Container -->
          <div id="aiSearchResultsList">
            <!-- Rendered dynamically -->
          </div>
        </div>
      </div>

      <!-- ==================== PHASE 2: MEETING COMPARISON ==================== -->
      <div class="page-view hidden" id="page-compare">
        <div class="desktop-content-body">
          <div class="welcome-stats-row">
            <div>
              <h2 class="welcome-title"><i class="ri-scales-3-line" style="color: var(--primary);"></i> Meeting Comparison Matrix</h2>
              <p class="welcome-sub">Select any two meetings to analyze progress, shifted deadlines, budget changes, and unresolved issues.</p>
            </div>
            <button class="btn-secondary" id="btnExportComparisonReport" title="Copy Markdown or Export Comparison">
              <i class="ri-file-copy-line"></i> Copy Comparison Report
            </button>
          </div>

          <div class="compare-selector-grid">
            <div class="compare-meeting-card">
              <label style="font-size: 12px; font-weight: 700; color: var(--text-dim); text-transform: uppercase; margin-bottom: 6px; display: block;">Meeting A (Baseline)</label>
              <select id="compareMeetingASelect" class="panel-input" style="margin-bottom: 10px;"></select>
              <p id="compareMeetingAMeta" style="font-size: 11.5px; color: var(--text-dim);">Select first meeting to compare</p>
            </div>
            <div class="compare-meeting-card">
              <label style="font-size: 12px; font-weight: 700; color: var(--text-dim); text-transform: uppercase; margin-bottom: 6px; display: block;">Meeting B (Follow-up)</label>
              <select id="compareMeetingBSelect" class="panel-input" style="margin-bottom: 10px;"></select>
              <p id="compareMeetingBMeta" style="font-size: 11.5px; color: var(--text-dim);">Select second meeting to compare</p>
            </div>
          </div>

          <div style="text-align: center; margin-bottom: 20px;">
            <button class="btn-primary-purple" id="btnRunMeetingComparison" style="padding: 10px 24px; font-size: 13.5px;">
              <i class="ri-magic-line"></i> Run AI Meeting Comparison
            </button>
          </div>

          <!-- Comparison Executive Delta Card -->
          <div class="ai-synthesis-card hidden" id="compareDeltaCard">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
              <h4 style="font-size: 14px; font-weight: 700; color: var(--primary);">
                <i class="ri-line-chart-line"></i> Executive Delta Analysis
              </h4>
              <span id="compareProgressBadge" class="sentiment-badge sentiment-positive">Progress: 85%</span>
            </div>
            <p id="compareDeltaText" style="font-size: 13.5px; line-height: 1.6; color: var(--text-main);"></p>
          </div>

          <!-- Comparison Matrix Table -->
          <div style="overflow-x: auto;">
            <table class="compare-matrix-table hidden" id="compareMatrixTable">
              <thead>
                <tr>
                  <th style="width: 18%;">Category</th>
                  <th style="width: 30%;">Meeting A</th>
                  <th style="width: 30%;">Meeting B</th>
                  <th style="width: 22%;">AI Delta &amp; Status</th>
                </tr>
              </thead>
              <tbody id="compareMatrixTbody">
                <!-- Rows dynamically injected -->
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- ==================== PHASE 2: MEETING MEMORY ENGINE ==================== -->
      <div class="page-view hidden" id="page-memory">
        <div class="desktop-content-body">
          <div class="welcome-stats-row">
            <div>
              <h2 class="welcome-title"><i class="ri-brain-line" style="color: var(--primary);"></i> Persistent Meeting Memory</h2>
              <p class="welcome-sub">Long-term organizational memory structured across 10 critical operational dimensions.</p>
            </div>
            <button class="btn-primary-purple" id="btnAddMemoryModalBtn">
              <i class="ri-add-line"></i> Add Memory Entry
            </button>
          </div>

          <!-- 10 Categories Filter Tabs -->
          <div class="memory-nav-tabs" id="memoryCategoriesTabs">
            <button class="memory-tab-btn active" data-cat="all">All Memories</button>
            <button class="memory-tab-btn" data-cat="Important Decisions">Decisions</button>
            <button class="memory-tab-btn" data-cat="Financial Discussions">Financial / Budget</button>
            <button class="memory-tab-btn" data-cat="Deadlines">Deadlines</button>
            <button class="memory-tab-btn" data-cat="Employee Responsibilities">Responsibilities</button>
            <button class="memory-tab-btn" data-cat="Project Information">Project Info</button>
            <button class="memory-tab-btn" data-cat="Client Information">Client Info</button>
            <button class="memory-tab-btn" data-cat="Unresolved Issues">Unresolved Issues</button>
            <button class="memory-tab-btn" data-cat="Recurring Topics">Recurring Topics</button>
            <button class="memory-tab-btn" data-cat="Promises and Commitments">Promises</button>
            <button class="memory-tab-btn" data-cat="Historical Changes">Changes</button>
          </div>

          <!-- Memory Cards Grid -->
          <div class="memory-cards-grid" id="memoryCardsGrid">
            <!-- Dynamically populated -->
          </div>
        </div>
      </div>

      <!-- ==================== PHASE 2: COMPANY KNOWLEDGE BASE ==================== -->
      <div class="page-view hidden" id="page-knowledge-base">
        <div class="desktop-content-body">
          <div class="welcome-stats-row">
            <div>
              <h2 class="welcome-title"><i class="ri-book-read-line" style="color: var(--primary);"></i> Company Knowledge Base (RAG)</h2>
              <p class="welcome-sub">Upload policies, proposals, and contracts in PDF, DOCX, TXT, or CSV to connect with meeting intelligence.</p>
            </div>
          </div>

          <!-- Drag and drop upload zone -->
          <div class="kb-upload-dropzone" id="kbUploadDropzone">
            <i class="ri-upload-cloud-2-line" style="font-size: 38px; color: var(--primary); margin-bottom: 8px; display: inline-block;"></i>
            <h4 style="font-size: 15px; font-weight: 700; margin-bottom: 4px;">Drag &amp; Drop Business Documents Here</h4>
            <p style="font-size: 12px; color: var(--text-dim); margin-bottom: 12px;">Supported formats: <span class="fmt-badge">PDF</span> <span class="fmt-badge">DOCX</span> <span class="fmt-badge">TXT</span> <span class="fmt-badge">CSV</span> (Max 15MB)</p>
            <input type="file" id="kbFileInput" accept=".pdf,.docx,.doc,.txt,.csv,.md" style="display: none;">
            <button class="btn-primary-purple" id="btnBrowseKbDoc">
              <i class="ri-folder-upload-line"></i> Browse Files
            </button>
          </div>

          <!-- Document List Table -->
          <div style="overflow-x: auto;">
            <table class="meetings-table" id="kbDocumentsTable">
              <thead>
                <tr>
                  <th>Document Title</th>
                  <th>Category</th>
                  <th>Type</th>
                  <th>Size</th>
                  <th>Indexed Chunks</th>
                  <th>Status</th>
                  <th style="text-align: right;">Actions</th>
                </tr>
              </thead>
              <tbody id="kbDocumentsTableBody">
                <!-- Dynamically populated -->
              </tbody>
            </table>
          </div>
        </div>
      </div>

      `;

if (html.includes(targetPage5)) {
  html = html.replace(targetPage5, phase2Views + targetPage5);
}

// 3. Upgrade Chat layout with Scope Switcher Bar
const oldChatHeader = `<div class="chat-header-bar">
              <div class="ai-avatar-glow"><i class="ri-sparkling-fill"></i></div>
              <div>
                <h3 class="chat-title">Ask Your Meetings — AI Chat</h3>
                <p class="chat-sub">Conversational search with grounded timestamp citations.</p>
              </div>
              <button class="btn-secondary" id="btnClearChatHistory" style="margin-left: auto;">
                <i class="ri-delete-bin-line"></i> Clear Chat
              </button>
            </div>`;

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
            </div>`;

if (html.includes(oldChatHeader)) {
  html = html.replace(oldChatHeader, newChatHeader);
}

fs.writeFileSync('app.html', html, 'utf8');
console.log('Successfully updated app.html with Phase 2 views and navigation!');

