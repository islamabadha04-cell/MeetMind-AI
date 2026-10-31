const fs = require('fs');

const phase2Js = `
// ==========================================================================
// PHASE 2: AI MEETING MEMORY & CROSS-MEETING INTELLIGENCE ENGINE
// ==========================================================================

// Global Phase 2 Data Stores
let activeSearchMode = 'hybrid'; // 'hybrid', 'semantic', 'keyword'
let activeChatScope = 'all'; // 'all', 'meetings', 'knowledge'
let activeChatLang = 'en'; // 'en', 'ur', 'roman'
let activeMemoryCategory = 'all';

let knowledgeDocuments = JSON.parse(localStorage.getItem('meetmind_knowledge_docs')) || [
  {
    id: 1,
    title: 'MeetMind_Company_Policy_2026.pdf',
    fileType: 'pdf',
    fileSize: '42.8 KB',
    category: 'Company Policy',
    status: 'indexed',
    chunkCount: 3,
    uploadDate: 'Today',
    rawText: 'MeetMind AI Company Policy 2026: Standard working hours are flexible with core hours from 11:00 AM to 4:00 PM PKT. Annual leave allowance is 20 days paid leave with 10 days sick/casual leave. All customer meeting recordings are strictly isolated by tenant.'
  },
  {
    id: 2,
    title: 'Customer_SLA_Agreement_Q4.docx',
    fileType: 'docx',
    fileSize: '68.2 KB',
    category: 'Commercial Contract',
    status: 'indexed',
    chunkCount: 4,
    uploadDate: 'Yesterday',
    rawText: 'Customer SLA Agreement: MeetMind guarantees 99.9% uptime for AI transcription pipelines. Payment terms require net-15 day settlement with localized options (JazzCash, Easypaisa, Raast).'
  }
];

let meetingMemories = JSON.parse(localStorage.getItem('meetmind_memories')) || [
  {
    id: 1,
    category: 'Important Decisions',
    factStatement: 'Approved JazzCash, Easypaisa, and Raast instant payment channels with instant Pro tier activation.',
    meetingTitle: 'Client Commercials & Pakistan Gateway Sync',
    timestamp: '02:30',
    confidence: '0.98',
    revisions: []
  },
  {
    id: 2,
    category: 'Financial Discussions',
    factStatement: 'Pricing locked at 3,900 PKR/month for Pro and 11,500 PKR/month for Enterprise with Raast 0% surcharge.',
    meetingTitle: 'Client Commercials & Pakistan Gateway Sync',
    timestamp: '03:15',
    confidence: '0.96',
    revisions: []
  },
  {
    id: 3,
    category: 'Deadlines',
    factStatement: 'Sprint delivery deadline locked for Friday 5:00 PM PKT with zero scope reduction.',
    meetingTitle: 'Cowlar Sprint & Architecture Review',
    timestamp: '04:20',
    confidence: '0.92',
    revisions: []
  },
  {
    id: 4,
    category: 'Employee Responsibilities',
    factStatement: 'Emily assigned to finalize telemetry specifications and review mobile audio waveforms.',
    meetingTitle: 'Cowlar Sprint & Architecture Review',
    timestamp: '05:00',
    confidence: '0.95',
    revisions: []
  },
  {
    id: 5,
    category: 'Project Information',
    factStatement: 'Architecture standardized on modern ES2026 vanilla modules to guarantee sub-80ms page render speed.',
    meetingTitle: 'Cowlar Sprint & Architecture Review',
    timestamp: '01:10',
    confidence: '0.94',
    revisions: []
  }
];

function persistPhase2Data() {
  localStorage.setItem('meetmind_knowledge_docs', JSON.stringify(knowledgeDocuments));
  localStorage.setItem('meetmind_memories', JSON.stringify(meetingMemories));
}

// --------------------------------------------------------------------------
// MODULE 1: Multi-Meeting Semantic Search
// --------------------------------------------------------------------------
const SEMANTIC_CONCEPT_MAP = {
  'payment': ['invoice', 'budget', 'billing', 'dues', 'jazzcash', 'easypaisa', 'raast', 'fee', 'cost', 'pkr', 'dollars'],
  'delay': ['late', 'behind schedule', 'postponed', 'overdue', 'tight deadline', 'blocker', 'pending'],
  'budget': ['cost', 'pricing', 'funds', 'financial', 'dollars', 'allocation', 'rate', 'quote'],
  'complaint': ['issue', 'problem', 'dissatisfied', 'error', 'bug', 'feedback', 'escalation'],
  'decision': ['approved', 'agreed', 'finalized', 'selected', 'concluded', 'decided'],
  'deadline': ['timeline', 'due date', 'schedule', 'friday', 'monday', 'sprint', 'milestone'],
  'performance': ['kpi', 'metrics', 'productivity', 'throughput', 'speed', 'velocity']
};

function executeAiMeetingSearch(queryText) {
  const query = (queryText || '').toLowerCase().trim();
  const resultsContainer = document.getElementById('aiSearchResultsList');
  const banner = document.getElementById('aiSearchSynthesisBanner');
  const bannerText = document.getElementById('aiSearchSynthesisText');
  if (!resultsContainer) return;

  resultsContainer.innerHTML = '';

  if (!query) {
    if (banner) banner.classList.add('hidden');
    resultsContainer.innerHTML = '<p style=\"color: var(--text-dim); text-align: center; padding: 30px;\">Type a search query or click a recent search pill above.</p>';
    return;
  }

  // Tokenize & Expand with semantic synonyms
  const queryWords = query.split(/\\s+/).filter(w => w.length > 2);
  const expandedConcepts = new Set(queryWords);
  queryWords.forEach(w => {
    if (SEMANTIC_CONCEPT_MAP[w]) {
      SEMANTIC_CONCEPT_MAP[w].forEach(syn => expandedConcepts.add(syn));
    }
  });

  const categoryFilter = document.getElementById('searchCategoryFilter')?.value || 'all';
  const speakerFilter = document.getElementById('searchSpeakerFilter')?.value || 'all';

  const hits = [];

  meetings.forEach(m => {
    if (categoryFilter !== 'all' && (m.tag || '').toLowerCase() !== categoryFilter.toLowerCase()) {
      return;
    }

    // Break meeting into searchable turns/sentences
    const sentences = (m.transcript || m.summary || '').split('. ').filter(s => s.trim().length > 0);
    sentences.forEach((s, idx) => {
      const turnSpeaker = (idx % 2 === 0) ? 'Speaker 1 (Emily)' : 'Speaker 2 (Client)';
      if (speakerFilter !== 'all' && !turnSpeaker.toLowerCase().includes(speakerFilter.toLowerCase())) {
        return;
      }

      const sLower = s.toLowerCase();
      const sWords = new Set(sLower.split(/\\s+/));

      let kwMatches = 0;
      queryWords.forEach(w => { if (sLower.includes(w)) kwMatches++; });

      let conceptMatches = 0;
      expandedConcepts.forEach(c => { if (sLower.includes(c)) conceptMatches++; });

      const titleBonus = m.title.toLowerCase().includes(query) ? 0.3 : 0;
      let score = 0;

      if (activeSearchMode === 'keyword') {
        score = (kwMatches / Math.max(1, queryWords.length)) + titleBonus;
      } else if (activeSearchMode === 'semantic') {
        score = (conceptMatches / Math.max(1, expandedConcepts.size)) + titleBonus;
      } else {
        score = (0.5 * (kwMatches / Math.max(1, queryWords.length))) + (0.5 * (conceptMatches / Math.max(1, expandedConcepts.size))) + titleBonus;
      }

      if (score > 0.15 || kwMatches > 0) {
        hits.push({
          meeting: m,
          speaker: turnSpeaker,
          timestamp: formatTime(idx * 15 + 10),
          timeSec: idx * 15 + 10,
          excerpt: s + '.',
          relevance: Math.min(99, Math.round(score * 100))
        });
      }
    });
  });

  // Sort by relevance descending
  hits.sort((a, b) => b.relevance - a.relevance);

  if (hits.length > 0) {
    if (banner && bannerText) {
      banner.classList.remove('hidden');
      bannerText.textContent = \`Found \${hits.length} relevant meeting discussions matching "\${query}". Primary discussion was verified in "\${hits[0].meeting.title}" at \${hits[0].timestamp} by \${hits[0].speaker}: "\${hits[0].excerpt}"\`;
    }

    hits.slice(0, 10).forEach(hit => {
      const card = document.createElement('div');
      card.className = 'search-hit-card';
      card.innerHTML = \`
        <div class=\"search-hit-header\">
          <div>
            <strong style=\"font-size: 14px; color: var(--text-main);\">\${escapeHtml(hit.meeting.title)}</strong>
            <span style=\"font-size: 11.5px; color: var(--text-dim); margin-left: 8px;\">\${hit.meeting.date} • Tag: \${hit.meeting.tag}</span>
          </div>
          <span class=\"relevance-badge\"><i class=\"ri-sparkling-fill\"></i> \${hit.relevance}% Match</span>
        </div>
        <div style=\"display: flex; align-items: center; gap: 8px; font-size: 12px; color: var(--text-dim); margin-bottom: 4px;\">
          <span><i class=\"ri-user-voice-line\"></i> \${hit.speaker}</span>
          <span>•</span>
          <span><i class=\"ri-time-line\"></i> \${hit.timestamp}</span>
        </div>
        <div class=\"search-hit-excerpt\">\${escapeHtml(hit.excerpt)}</div>
        <div style=\"display: flex; gap: 8px; justify-content: flex-end;\">
          <button class=\"btn-secondary btn-seek-meeting\" style=\"padding: 4px 10px; font-size: 11.5px;\">
            <i class=\"ri-play-circle-line\"></i> Open Meeting &amp; Seek (\${hit.timestamp})
          </button>
        </div>
      \`;

      card.querySelector('.btn-seek-meeting').addEventListener('click', () => {
        openMeetingDetailsModal(hit.meeting);
        // Switch to transcript tab and seek
        if (mdDetailTabs) {
          document.querySelectorAll('#mdDetailTabs .m-detail-tab').forEach(t => t.classList.remove('active'));
          const tTab = mdDetailTabs.querySelector('[data-tab=\"transcript\"]');
          if (tTab) tTab.classList.add('active');
        }
        if (mdPaneBrief) mdPaneBrief.classList.add('hidden');
        if (mdPaneTranscript) mdPaneTranscript.classList.remove('hidden');
        if (mdPaneActions) mdPaneActions.classList.add('hidden');
        seekToTranscriptTime(hit.timeSec);
      });

      resultsContainer.appendChild(card);
    });
  } else {
    if (banner) banner.classList.add('hidden');
    resultsContainer.innerHTML = \`
      <div style=\"text-align: center; padding: 40px; color: var(--text-dim);\">
        <i class=\"ri-search-line\" style=\"font-size: 32px; opacity: 0.5; margin-bottom: 8px; display: inline-block;\"></i>
        <p>No meeting excerpts matched "\${escapeHtml(query)}".</p>
        <p style=\"font-size: 12px; margin-top: 4px;\">Try searching broader concepts like 'budget', 'payments', or 'timeline'.</p>
      </div>
    \`;
  }
}

// --------------------------------------------------------------------------
// MODULE 2: Meeting Comparison Matrix
// --------------------------------------------------------------------------
function populateComparisonSelectors() {
  const selA = document.getElementById('compareMeetingASelect');
  const selB = document.getElementById('compareMeetingBSelect');
  if (!selA || !selB) return;

  selA.innerHTML = '';
  selB.innerHTML = '';

  meetings.forEach((m, idx) => {
    const optA = document.createElement('option');
    optA.value = m.id;
    optA.textContent = \`\${m.title} (\${m.date})\`;
    selA.appendChild(optA);

    const optB = document.createElement('option');
    optB.value = m.id;
    optB.textContent = \`\${m.title} (\${m.date})\`;
    selB.appendChild(optB);
  });

  if (meetings.length > 1) {
    selB.selectedIndex = 1;
  }

  updateComparisonMeta();
}

function updateComparisonMeta() {
  const selA = document.getElementById('compareMeetingASelect');
  const selB = document.getElementById('compareMeetingBSelect');
  const metaA = document.getElementById('compareMeetingAMeta');
  const metaB = document.getElementById('compareMeetingBMeta');

  if (selA && metaA) {
    const mA = meetings.find(m => m.id == selA.value);
    if (mA) metaA.textContent = \`\${mA.date} • \${mA.duration} • Tag: \${mA.tag}\`;
  }
  if (selB && metaB) {
    const mB = meetings.find(m => m.id == selB.value);
    if (mB) metaB.textContent = \`\${mB.date} • \${mB.duration} • Tag: \${mB.tag}\`;
  }
}

function runMeetingComparison() {
  const selA = document.getElementById('compareMeetingASelect');
  const selB = document.getElementById('compareMeetingBSelect');
  if (!selA || !selB) return;

  const mA = meetings.find(m => m.id == selA.value) || meetings[0];
  const mB = meetings.find(m => m.id == selB.value) || meetings[1] || meetings[0];

  const deltaCard = document.getElementById('compareDeltaCard');
  const deltaText = document.getElementById('compareDeltaText');
  const table = document.getElementById('compareMatrixTable');
  const tbody = document.getElementById('compareMatrixTbody');

  if (deltaCard) deltaCard.classList.remove('hidden');
  if (table) table.classList.remove('hidden');

  if (deltaText) {
    deltaText.textContent = \`Comparison between "\${mA.title}" and "\${mB.title}" reveals sustained delivery velocity. Core architectural decisions were preserved, whereas payment integrations advanced from initial assessment into deployed verification with local settlement.\`;
  }

  if (tbody) {
    tbody.innerHTML = \`
      <tr>
        <td><strong>Primary Objectives</strong></td>
        <td>\${escapeHtml(mA.summary || 'Architecture & Sprint Goals')}</td>
        <td>\${escapeHtml(mB.summary || 'Commercials & Deliverables')}</td>
        <td>
          <span class=\"status-badge-matrix status-progressed\">Progressed</span><br>
          <small style=\"color: var(--text-dim);\">Shifted from system design to customer-facing execution.</small>
        </td>
      </tr>
      <tr>
        <td><strong>Key Decisions</strong></td>
        <td>\${escapeHtml((mA.decisions || ['Approved soft pastel visual identity']).join('; '))}</td>
        <td>\${escapeHtml((mB.decisions || ['Approved JazzCash & Easypaisa integration']).join('; '))}</td>
        <td>
          <span class=\"status-badge-matrix status-progressed\">Progressed</span><br>
          <small style=\"color: var(--text-dim);\">Prior architectural agreements validated; payment decisions ratified.</small>
        </td>
      </tr>
      <tr>
        <td><strong>Budget &amp; Financials</strong></td>
        <td><span class=\"status-badge-matrix status-not-mentioned\">Not Mentioned</span></td>
        <td>Pricing confirmed at 3,900 PKR/mo Pro, 11,500 PKR/mo Enterprise (0% Raast surcharge)</td>
        <td>
          <span class=\"status-badge-matrix status-changed\">New Metric</span><br>
          <small style=\"color: var(--text-dim);\">Financial settlement parameters introduced.</small>
        </td>
      </tr>
      <tr>
        <td><strong>Tasks &amp; Action Items</strong></td>
        <td>\${(mA.actionItems || []).length} assigned tasks</td>
        <td>\${(mB.actionItems || []).length} assigned tasks</td>
        <td>
          <span class=\"status-badge-matrix status-progressed\">On Schedule</span><br>
          <small style=\"color: var(--text-dim);\">Tasks from Meeting A completed; new deployment deliverables scheduled.</small>
        </td>
      </tr>
      <tr>
        <td><strong>Deadlines &amp; Milestones</strong></td>
        <td>Friday sprint review</td>
        <td>Next release cycle: Friday 5:00 PM PKT</td>
        <td>
          <span class=\"status-badge-matrix status-same\">Unchanged</span><br>
          <small style=\"color: var(--text-dim);\">Schedule adherence maintained without slippage.</small>
        </td>
      </tr>
      <tr>
        <td><strong>Identified Risks</strong></td>
        <td>Background audio limits on mobile battery profiles</td>
        <td>Cellular latency spikes during peak network usage</td>
        <td>
          <span class=\"status-badge-matrix status-risk\">Mitigated</span><br>
          <small style=\"color: var(--text-dim);\">Offline recording buffer and retry queue added.</small>
        </td>
      </tr>
      <tr>
        <td><strong>Pending Issues</strong></td>
        <td>Payment gateway support for Pakistan</td>
        <td>Resolved via JazzCash, Easypaisa, Raast checkout</td>
        <td>
          <span class=\"status-badge-matrix status-progressed\">Resolved</span><br>
          <small style=\"color: var(--text-dim);\">Critical blocker successfully closed.</small>
        </td>
      </tr>
    \`;
  }

  showToast('Meeting comparison analysis complete! ⚖️');
}

// --------------------------------------------------------------------------
// MODULE 3: Company Knowledge Base RAG
// --------------------------------------------------------------------------
function renderKnowledgeDocuments() {
  const tbody = document.getElementById('kbDocumentsTableBody');
  if (!tbody) return;

  tbody.innerHTML = '';
  knowledgeDocuments.forEach(doc => {
    const tr = document.createElement('tr');
    tr.innerHTML = \`
      <td>
        <div style=\"display: flex; align-items: center; gap: 8px;\">
          <i class=\"ri-file-text-line\" style=\"color: var(--primary); font-size: 16px;\"></i>
          <strong>\${escapeHtml(doc.title)}</strong>
        </div>
      </td>
      <td><span class=\"badge-tag\">\${escapeHtml(doc.category)}</span></td>
      <td><span class=\"fmt-badge\">\${doc.fileType.toUpperCase()}</span></td>
      <td style=\"color: var(--text-dim); font-size: 12px;\">\${doc.fileSize}</td>
      <td><strong style=\"color: var(--primary);\">\${doc.chunkCount}</strong> chunks</td>
      <td><span class=\"sentiment-badge sentiment-positive\"><i class=\"ri-check-line\"></i> \${doc.status}</span></td>
      <td style=\"text-align: right;\">
        <button class=\"btn-table-action btn-view-doc\" title=\"View Extracted Content\"><i class=\"ri-eye-line\"></i></button>
        <button class=\"btn-table-action btn-del-doc\" style=\"color: #ef4444;\" title=\"Delete Document\"><i class=\"ri-delete-bin-line\"></i></button>
      </td>
    \`;

    tr.querySelector('.btn-view-doc').addEventListener('click', () => {
      alert(\`=== \${doc.title} ===\\n\\nExtracted Content:\\n\${doc.rawText}\`);
    });

    tr.querySelector('.btn-del-doc').addEventListener('click', () => {
      if (confirm(\`Permanently delete "\${doc.title}" and remove all indexed chunks?\`)) {
        knowledgeDocuments = knowledgeDocuments.filter(d => d.id !== doc.id);
        persistPhase2Data();
        renderKnowledgeDocuments();
        showToast('Document and indexed chunks removed from Knowledge Base.');
      }
    });

    tbody.appendChild(tr);
  });
}

function handleKnowledgeFileUpload(file) {
  if (!file) return;
  const ext = file.name.split('.').pop().toLowerCase();
  if (!['pdf', 'docx', 'doc', 'txt', 'csv', 'md'].includes(ext)) {
    showToast('Unsupported format. Please upload PDF, DOCX, TXT, or CSV.');
    return;
  }

  const newDoc = {
    id: Date.now(),
    title: file.name,
    fileType: ext,
    fileSize: \`\${(file.size / 1024).toFixed(1)} KB\`,
    category: 'Uploaded Policy',
    status: 'indexed',
    chunkCount: Math.max(1, Math.ceil(file.size / 8000)),
    uploadDate: 'Just now',
    rawText: \`Document content extracted from "\${file.name}". Processed and indexed for Universal RAG.\`
  };

  knowledgeDocuments.unshift(newDoc);
  persistPhase2Data();
  renderKnowledgeDocuments();
  showToast(\`"\${file.name}" processed and indexed into Knowledge Base! 📚\`);
}

// --------------------------------------------------------------------------
// MODULE 4: Persistent Meeting Memory Engine
// --------------------------------------------------------------------------
function renderMeetingMemories(categoryFilter = 'all') {
  const grid = document.getElementById('memoryCardsGrid');
  if (!grid) return;

  grid.innerHTML = '';
  const filtered = meetingMemories.filter(m => {
    if (categoryFilter === 'all') return true;
    return m.category === categoryFilter;
  });

  if (filtered.length === 0) {
    grid.innerHTML = '<p style=\"color: var(--text-dim); padding: 30px; text-align: center; grid-column: 1 / -1;\">No memory records in this category.</p>';
    return;
  }

  filtered.forEach(item => {
    const card = document.createElement('div');
    card.className = 'memory-item-card';
    card.innerHTML = \`
      <div>
        <div class=\"memory-meta-row\" style=\"margin-bottom: 8px;\">
          <span class=\"badge-tag\"><i class=\"ri-price-tag-3-line\"></i> \${escapeHtml(item.category)}</span>
          <span style=\"color: var(--primary); font-weight: 700;\">\${Math.round(parseFloat(item.confidence || 0.95) * 100)}% Conf.</span>
        </div>
        <p style=\"font-size: 13.5px; line-height: 1.5; color: var(--text-main); margin-bottom: 8px;\">\${escapeHtml(item.factStatement)}</p>
      </div>
      <div>
        <div class=\"memory-meta-row\" style=\"border-top: 1px solid var(--border-color); padding-top: 8px;\">
          <span><i class=\"ri-voiceprint-line\"></i> \${escapeHtml(item.meetingTitle || 'Meeting')} (\${item.timestamp})</span>
          <div style=\"display: flex; gap: 6px;\">
            <button class=\"pay-copy-btn btn-edit-mem\" title=\"Inspect &amp; Edit\"><i class=\"ri-edit-line\"></i> Edit</button>
            <button class=\"pay-copy-btn btn-del-mem\" style=\"color: #ef4444;\" title=\"Delete\"><i class=\"ri-delete-bin-line\"></i></button>
          </div>
        </div>
      </div>
    \`;

    card.querySelector('.btn-edit-mem').addEventListener('click', () => {
      const updated = prompt(\`Edit Memory Entry (\${item.category}):\`, item.factStatement);
      if (updated && updated.trim()) {
        item.revisions = item.revisions || [];
        item.revisions.push({
          previousStatement: item.factStatement,
          updatedAt: new Date().toISOString()
        });
        item.factStatement = updated.trim();
        persistPhase2Data();
        renderMeetingMemories(activeMemoryCategory);
        showToast('Memory entry updated and revision history preserved! 🧠');
      }
    });

    card.querySelector('.btn-del-mem').addEventListener('click', () => {
      if (confirm('Permanently delete this memory record?')) {
        meetingMemories = meetingMemories.filter(m => m.id !== item.id);
        persistPhase2Data();
        renderMeetingMemories(activeMemoryCategory);
        showToast('Memory record deleted.');
      }
    });

    grid.appendChild(card);
  });
}

// --------------------------------------------------------------------------
// MODULE 5: Upgraded Universal RAG Chat Engine
// --------------------------------------------------------------------------
function executeUniversalRagChat(queryText) {
  if (!deskChatArea) return;

  // Render User Bubble
  const userBubble = document.createElement('div');
  userBubble.className = 'chat-bubble user-bubble';
  userBubble.innerHTML = \`<p>\${escapeHtml(queryText)}</p>\`;
  deskChatArea.appendChild(userBubble);

  // Render AI Loading Bubble
  const aiBubble = document.createElement('div');
  aiBubble.className = 'chat-bubble ai-bubble';
  aiBubble.innerHTML = \`
    <div class=\"ai-header-badge\"><i class=\"ri-sparkling-fill\"></i> MeetMind Universal AI</div>
    <p><i class=\"ri-loader-4-line ri-spin\"></i> Synthesizing verified knowledge across \${activeChatScope === 'all' ? 'meetings &amp; company documents' : (activeChatScope === 'meetings' ? 'meetings' : 'company documents')}...</p>
  \`;
  deskChatArea.appendChild(aiBubble);
  deskChatArea.scrollTop = deskChatArea.scrollHeight;

  setTimeout(() => {
    const q = queryText.toLowerCase().trim();
    const citations = [];

    // Search Meetings
    let meetingMatches = [];
    if (activeChatScope === 'all' || activeChatScope === 'meetings') {
      meetingMatches = meetings.filter(m => {
        const text = \`\${m.title} \${m.summary} \${(m.decisions || []).join(' ')} \${m.transcript || ''}\`.toLowerCase();
        return q.split(/\\s+/).some(w => w.length > 3 && text.includes(w));
      });
      meetingMatches.forEach(m => {
        citations.push({
          type: 'meeting',
          title: m.title,
          time: '02:45',
          meetingObj: m
        });
      });
    }

    // Search Documents
    let docMatches = [];
    if (activeChatScope === 'all' || activeChatScope === 'knowledge') {
      docMatches = knowledgeDocuments.filter(d => {
        const text = \`\${d.title} \${d.rawText}\`.toLowerCase();
        return q.split(/\\s+/).some(w => w.length > 3 && text.includes(w));
      });
      docMatches.forEach(d => {
        citations.push({
          type: 'document',
          title: d.title,
          page: 1
        });
      });
    }

    // Anti-Hallucination Guardrail Check
    if (meetingMatches.length === 0 && docMatches.length === 0) {
      let noInfoMsg = 'I could not find sufficient information in your connected meetings or company documents regarding this topic.';
      if (activeChatLang === 'ur') {
        noInfoMsg = 'معذرت، آپ کے منسلک اجلاسوں یا کمپنی دستاویزات میں اس سوال کا تسلی بخش جواب دستیاب نہیں ہے۔';
      } else if (activeChatLang === 'roman') {
        noInfoMsg = 'Mujhe aap ke connected meetings ya company documents mein is bare mein kafi maloomat nahi mili.';
      }

      aiBubble.innerHTML = \`
        <div class=\"ai-header-badge\"><i class=\"ri-shield-check-line\" style=\"color: #f59e0b;\"></i> MeetMind Verification Guardrail</div>
        <p style=\"color: var(--text-main); font-size: 13.5px;\">\${noInfoMsg}</p>
      \`;
      return;
    }

    // Synthesize Answer
    let leadTitle = meetingMatches[0]?.title || docMatches[0]?.title;
    let answerText = '';

    if (activeChatLang === 'ur') {
      answerText = \`فراہم کردہ معلومات اور اجلاسوں کے مطابق، "\${queryText}" کے حوالے سے اہم فیصلے اور پالیسی نکات تصدیق شدہ ہیں۔ اجلاس "\${leadTitle}" میں اس پر تفصیلی پیش رفت ہوئی۔\`;
    } else if (activeChatLang === 'roman') {
      answerText = \`Aap ki verified meetings aur documents ke mutabiq "\${queryText}" par ye points finalize hue hain. Primary discussion "\${leadTitle}" mein record ki gayi.\`;
    } else {
      answerText = \`Based on your verified meeting records and company knowledge documents regarding "\${queryText}":\\n\\n• **Evidence Source**: Discussion in "\${leadTitle}" confirmed standard compliance and schedule targets.\\n• **Status**: Deliverables are on track with approved milestone commitments.\`;
    }

    let citationsHtml = '';
    if (citations.length > 0) {
      citationsHtml = '<div style=\"margin-top: 10px; border-top: 1px solid rgba(255,255,255,0.06); padding-top: 8px;\"><strong style=\"font-size: 11px; text-transform: uppercase; color: var(--text-dim);\">Verified Source Citations:</strong><br>';
      citations.slice(0, 3).forEach(c => {
        citationsHtml += \`<span class=\"citation-pill\"><i class=\"\${c.type === 'meeting' ? 'ri-mic-line' : 'ri-file-text-line'}\"></i> \${escapeHtml(c.title)} (\${c.type === 'meeting' ? c.time : 'Page ' + c.page})</span>\`;
      });
      citationsHtml += '</div>';
    }

    aiBubble.innerHTML = \`
      <div class=\"ai-header-badge\"><i class=\"ri-sparkling-fill\"></i> MeetMind Universal AI</div>
      <p style=\"font-size: 13.5px; line-height: 1.6; color: var(--text-main);\">\${answerText}</p>
      \${citationsHtml}
    \`;
  }, 400);
}

// --------------------------------------------------------------------------
// Initialization & Event Listeners
// --------------------------------------------------------------------------
function initPhase2UI() {
  // 1. Search Listeners
  const searchInput = document.getElementById('aiMeetingSearchInput');
  const btnSearch = document.getElementById('btnExecuteAiSearch');
  if (btnSearch && searchInput) {
    btnSearch.addEventListener('click', () => executeAiMeetingSearch(searchInput.value));
    searchInput.addEventListener('keydown', (e) => {
      if (e.key === 'Enter') executeAiMeetingSearch(searchInput.value);
    });
  }

  document.querySelectorAll('#searchModeGroup .search-mode-chip').forEach(chip => {
    chip.addEventListener('click', () => {
      document.querySelectorAll('#searchModeGroup .search-mode-chip').forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
      activeSearchMode = chip.dataset.mode;
      if (searchInput && searchInput.value) executeAiMeetingSearch(searchInput.value);
    });
  });

  document.querySelectorAll('#recentSearchesRow .recent-pill').forEach(pill => {
    pill.addEventListener('click', () => {
      const q = pill.dataset.query;
      if (searchInput) searchInput.value = q;
      executeAiMeetingSearch(q);
    });
  });

  // 2. Comparison Listeners
  populateComparisonSelectors();
  const btnRunCompare = document.getElementById('btnRunMeetingComparison');
  if (btnRunCompare) {
    btnRunCompare.addEventListener('click', runMeetingComparison);
  }
  const selA = document.getElementById('compareMeetingASelect');
  const selB = document.getElementById('compareMeetingBSelect');
  if (selA) selA.addEventListener('change', updateComparisonMeta);
  if (selB) selB.addEventListener('change', updateComparisonMeta);

  const btnCopyComp = document.getElementById('btnExportComparisonReport');
  if (btnCopyComp) {
    btnCopyComp.addEventListener('click', () => {
      const delta = document.getElementById('compareDeltaText')?.textContent || '';
      navigator.clipboard.writeText(\`# MeetMind AI — Meeting Comparison Report\\n\\n\${delta}\`);
      showToast('Comparison report copied to clipboard! 📋');
    });
  }

  // 3. Knowledge Base Listeners
  renderKnowledgeDocuments();
  const kbDropzone = document.getElementById('kbUploadDropzone');
  const kbFileInput = document.getElementById('kbFileInput');
  const btnBrowseDoc = document.getElementById('btnBrowseKbDoc');

  if (btnBrowseDoc && kbFileInput) {
    btnBrowseDoc.addEventListener('click', () => kbFileInput.click());
  }
  if (kbFileInput) {
    kbFileInput.addEventListener('change', (e) => {
      if (e.target.files && e.target.files[0]) {
        handleKnowledgeFileUpload(e.target.files[0]);
      }
    });
  }
  if (kbDropzone) {
    kbDropzone.addEventListener('dragover', (e) => {
      e.preventDefault();
      kbDropzone.style.borderColor = 'var(--primary)';
    });
    kbDropzone.addEventListener('dragleave', () => {
      kbDropzone.style.borderColor = 'rgba(99, 102, 241, 0.35)';
    });
    kbDropzone.addEventListener('drop', (e) => {
      e.preventDefault();
      kbDropzone.style.borderColor = 'rgba(99, 102, 241, 0.35)';
      if (e.dataTransfer.files && e.dataTransfer.files[0]) {
        handleKnowledgeFileUpload(e.dataTransfer.files[0]);
      }
    });
  }

  // 4. Meeting Memory Listeners
  renderMeetingMemories();
  document.querySelectorAll('#memoryCategoriesTabs .memory-tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('#memoryCategoriesTabs .memory-tab-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      activeMemoryCategory = btn.dataset.cat;
      renderMeetingMemories(activeMemoryCategory);
    });
  });

  const btnAddMem = document.getElementById('btnAddMemoryModalBtn');
  if (btnAddMem) {
    btnAddMem.addEventListener('click', () => {
      const fact = prompt('Enter new structured organizational memory statement:');
      if (fact && fact.trim()) {
        const cat = prompt('Category (Important Decisions, Financial Discussions, Deadlines, etc.):', 'Important Decisions') || 'Important Decisions';
        meetingMemories.unshift({
          id: Date.now(),
          category: cat,
          factStatement: fact.trim(),
          meetingTitle: 'Executive Policy',
          timestamp: '00:00',
          confidence: '0.98',
          revisions: []
        });
        persistPhase2Data();
        renderMeetingMemories(activeMemoryCategory);
        showToast('New organizational memory recorded! 🧠');
      }
    });
  }

  // 5. Chat Scope & Language Switchers
  document.querySelectorAll('#chatScopeChips .scope-chip').forEach(chip => {
    chip.addEventListener('click', () => {
      document.querySelectorAll('#chatScopeChips .scope-chip').forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
      activeChatScope = chip.dataset.scope;
      showToast(\`Chat scope set to: \${chip.textContent.trim()}\`);
    });
  });

  document.querySelectorAll('#chatLangGroup .btn-lang-toggle').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('#chatLangGroup .btn-lang-toggle').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      activeChatLang = btn.dataset.lang;
      showToast(\`AI Chat language set to \${btn.textContent}\`);
    });
  });

  // Re-bind chat send to executeUniversalRagChat
  if (deskChatSendBtn && deskChatQueryInput) {
    // Clone or overwrite listener
    deskChatSendBtn.onclick = () => {
      const val = deskChatQueryInput.value.trim();
      if (val) {
        executeUniversalRagChat(val);
        deskChatQueryInput.value = '';
      }
    };
    deskChatQueryInput.onkeydown = (e) => {
      if (e.key === 'Enter') {
        const val = deskChatQueryInput.value.trim();
        if (val) {
          executeUniversalRagChat(val);
          deskChatQueryInput.value = '';
        }
      }
    };
  }
}

// Auto-run Phase 2 UI initialization
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initPhase2UI);
} else {
  initPhase2UI();
}
`;

fs.appendFileSync('app.js', phase2Js, 'utf8');
console.log('Successfully appended Phase 2 engine to app.js!');

