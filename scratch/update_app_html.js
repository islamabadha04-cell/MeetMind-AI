const fs = require('fs');

let content = fs.readFileSync('app.html', 'utf8');

// 1. Add Punjabi & Mixed chips in studioLangGroup
const oldLangRegex = /<div class="lang-selector-group" id="studioLangGroup">[\s\S]*?<\/div>\s*<div class="studio-tag-badge">/;
const newLang = `<div class="lang-selector-group" id="studioLangGroup">
                <button class="lang-chip active" data-lang="en-US" id="btnLangEn" title="English Speech Recognition">
                  <i class="ri-global-line"></i> English (US)
                </button>
                <button class="lang-chip" data-lang="ur-PK" id="btnLangUr" title="Urdu Speech Recognition">
                  <i class="ri-translate-2"></i> اردو (Urdu)
                </button>
                <button class="lang-chip" data-lang="pa-PK" id="btnLangPa" title="Punjabi Speech Recognition">
                  <i class="ri-voiceprint-line"></i> پنجابی (Punjabi)
                </button>
                <button class="lang-chip" data-lang="mixed" id="btnLangMixed" title="Mixed Roman Urdu &amp; English">
                  <i class="ri-chat-voice-line"></i> Roman Urdu
                </button>
              </div>
              <div class="studio-tag-badge">`;

content = content.replace(oldLangRegex, newLang);

// 2. Replace mdPaneBrief section
const targetBriefRegex = /<!-- TAB A: Executive Brief & Decisions -->[\s\S]*?<!-- TAB B: Multi-Speaker Diarized Transcript -->/;
const replacementBrief = `<!-- TAB A: Executive Brief & Decisions -->
        <div class="md-tab-pane" id="mdPaneBrief">
          <!-- Multilingual & Persona Intelligence Toolbar -->
          <div class="lang-persona-toolbar">
            <div class="lang-btn-group" id="mdDetailLangGroup">
              <button class="btn-lang-toggle active" data-lang="en" id="btnMdLangEn" title="View in English">
                <i class="ri-global-line"></i> English
              </button>
              <button class="btn-lang-toggle" data-lang="ur" id="btnMdLangUr" title="اردو میں خلاصہ دیکھیں (Nastaliq)">
                <i class="ri-translate-2"></i> اردو (Nastaliq)
              </button>
              <button class="btn-lang-toggle" data-lang="roman" id="btnMdLangRoman" title="View in Roman Urdu">
                <i class="ri-chat-voice-line"></i> Roman Urdu
              </button>
            </div>
            
            <div class="persona-select-wrapper">
              <span class="persona-select-label"><i class="ri-magic-line"></i> Template:</span>
              <select class="persona-dropdown" id="mdPersonaSelect">
                <option value="executive">Executive Brief</option>
                <option value="technical">Technical Sprint &amp; Engineering</option>
                <option value="client">Client-Friendly MoM</option>
                <option value="urdu_official">Official Urdu MoM (سرکاری دستاویز)</option>
              </select>
              <button class="btn-secondary" id="btnToggleBilingualCompare" style="padding: 4px 8px; font-size: 11px;" title="Side-by-side English &amp; Urdu comparison">
                <i class="ri-split-cells-horizontal"></i> Compare
              </button>
            </div>
          </div>

          <!-- Executive Summary Section -->
          <div class="detail-section">
            <h4 style="font-size: 14px; font-weight: 700; margin-bottom: 6px; color: var(--primary); display: flex; align-items: center; justify-content: space-between;">
              <span><i class="ri-sparkling-fill"></i> Executive AI Summary</span>
              <span id="mdLangIndicatorBadge" style="font-size: 10.5px; padding: 2px 7px; background: rgba(99,102,241,0.15); border-radius: 10px; color: var(--primary); font-weight: 600;">English</span>
            </h4>
            <p id="mdDetailSummary" style="font-size: 13.5px; line-height: 1.6; color: var(--text-main);"></p>
            
            <!-- Side-by-Side Bilingual Comparison Box (Hidden by default) -->
            <div id="mdBilingualCompare" class="bilingual-compare-grid hidden">
              <div class="compare-card">
                <div class="compare-card-title"><i class="ri-global-line"></i> Source (English)</div>
                <p id="mdCompareSourceText" style="font-size: 12.5px; line-height: 1.5; color: var(--text-muted);"></p>
              </div>
              <div class="compare-card">
                <div class="compare-card-title"><i class="ri-translate-2"></i> اردو ترجمہ (Urdu Translation)</div>
                <p id="mdCompareTargetText" class="urdu-nastaliq-text" style="font-size: 14.5px; color: var(--text-main);"></p>
              </div>
            </div>
          </div>

          <!-- Meeting Risk & Sentiment Intelligence Radar -->
          <div class="meeting-intelligence-radar" id="mdIntelligenceRadar">
            <div class="radar-header">
              <div class="radar-title">
                <i class="ri-radar-line" style="color: var(--primary);"></i> Meeting Risk &amp; Sentiment Analysis
              </div>
              <div id="mdSentimentBadge" class="sentiment-badge sentiment-positive">
                <i class="ri-emotion-happy-line"></i> <span>Positive (88%)</span>
              </div>
            </div>
            <div class="risk-tiles-grid">
              <div class="risk-tile">
                <div class="risk-tile-header">
                  <span>Budget Risk</span>
                  <i class="ri-funds-line"></i>
                </div>
                <div class="risk-tile-status risk-status-green" id="mdRiskBudgetStatus">None (Safe)</div>
                <div class="risk-tile-desc" id="mdRiskBudgetDesc">All figures within allocated sprint boundaries.</div>
              </div>
              <div class="risk-tile">
                <div class="risk-tile-header">
                  <span>Deadline Risk</span>
                  <i class="ri-timer-flash-line"></i>
                </div>
                <div class="risk-tile-status risk-status-amber" id="mdRiskDeadlineStatus">Low - Tight Schedule</div>
                <div class="risk-tile-desc" id="mdRiskDeadlineDesc">Deliverables required within standard working days.</div>
              </div>
              <div class="risk-tile">
                <div class="risk-tile-header">
                  <span>Technical Risk</span>
                  <i class="ri-shield-check-line"></i>
                </div>
                <div class="risk-tile-status risk-status-green" id="mdRiskTechStatus">No Blockers</div>
                <div class="risk-tile-desc" id="mdRiskTechDesc">Dependencies verified and architectural path clear.</div>
              </div>
            </div>
          </div>

          <!-- Key Decisions Section -->
          <div class="detail-section" style="margin-top: 14px;">
            <h4 style="font-size: 14px; font-weight: 700; margin-bottom: 6px;">
              <i class="ri-check-double-line" style="color: var(--success);"></i> Key Decisions &amp; Verified Audio Timestamps
            </h4>
            <ul id="mdDetailDecisions" class="decisions-bullet-list"></ul>
          </div>
        </div>

        <!-- TAB B: Multi-Speaker Diarized Transcript -->`;

content = content.replace(targetBriefRegex, replacementBrief);
fs.writeFileSync('app.html', content, 'utf8');
console.log('Successfully updated app.html with Phase 1 components!');

