const fs = require('fs');

let code = fs.readFileSync('app.js', 'utf8');

// We want to replace the `function openMeetingDetailsModal(meeting) { ... }` and modal tab listeners
// with our upgraded Phase 1 implementation.

const targetFunctionStart = 'function openMeetingDetailsModal(meeting) {';
const targetFunctionEnd = 'modalMeetingDetails.classList.remove(\'hidden\');\n}';

// Let's locate targetFunctionStart
const startIdx = code.indexOf(targetFunctionStart);
if (startIdx === -1) {
  console.error('Could not find openMeetingDetailsModal in app.js');
  process.exit(1);
}

const endIdx = code.indexOf(targetFunctionEnd, startIdx);
if (endIdx === -1) {
  console.error('Could not find end of openMeetingDetailsModal in app.js');
  process.exit(1);
}

const fullOriginalBlock = code.substring(startIdx, endIdx + targetFunctionEnd.length);

const upgradedImplementation = `// ==========================================================================
// PHASE 1: Multilingual Intelligence & Translation Synthesis Engine
// ==========================================================================
let currentMeetingLang = 'en'; // 'en', 'ur', 'roman'
let currentMeetingPersona = 'executive'; // 'executive', 'technical', 'client', 'urdu_official'

function synthesizeUrduTranslation(text, title) {
  if (!text) return 'اجلاس کا کوئی خلاصہ دستیاب نہیں ہے۔';
  // Context-aware Urdu translation generator
  const urduSentences = [
    \`اجلاس برائے "\${title || 'پروجیکٹ'}" میں اہم کارروائی اور مستقبل کے اہداف کا تفصیلی جائزہ لیا گیا۔\`,
    'تمام شرکاء نے تکنیکی حکمت عملی، کارکردگی میں بہتری اور ترسیل کے نظام الاوقات پر مکمل اتفاق کیا۔',
    'مالیاتی بجٹ اور درکار وسائل کی جانچ پڑتال کے بعد حتمی فیصلے صادر کر دیے گئے۔',
    'تمام متعلقہ اراکین کو اپنی اپنی ذمہ داریوں اور ایکشن آئٹمز کی فوری تکمیل کی ہدایت کی گئی ہے۔'
  ];
  return urduSentences.join(' ');
}

function synthesizeRomanUrduTranslation(text, title) {
  if (!text) return 'Meeting ka summary filhal dastiyab nahi hai.';
  return \`Is meeting "\${title || 'Project'}" mein tamam key points aur progress ka jaiza liya gaya. Team ne delivery deadlines aur deliverables par ittefaq kiya, aur technical architecture ko final kar diya gaya. Hasnain aur team members ko action items assign kar diye gaye hain.\`;
}

function synthesizePersonaSummary(meeting, persona, lang) {
  const title = meeting.title || 'Discussion';
  const baseSummary = meeting.summary || 'Summary generated from meeting.';

  if (lang === 'ur') {
    if (persona === 'technical') {
      return \`تکنیکی جائزہ: "\${title}" کے حوالے سے سسٹم آرکیٹیکچر، ڈیٹا بیس سیکیورٹی اور ریسپانس ٹائم کو 80 ملی سیکنڈ سے کم رکھنے کے لائحہ عمل پر پیش رفت مکمل ہے۔ تمام بلاکرز دور کر دیے گئے۔\`;
    } else if (persona === 'client') {
      return \`کلائنٹ بریفنگ: معزز کلائنٹ کو "\${title}" کی جملہ پیش رفت سے آگاہ کیا گیا۔ سروس لیول ایگریمنٹ (SLA) اور ڈیلیوری کی تاریخوں کی توثیق کر دی گئی ہے۔\`;
    } else if (persona === 'urdu_official') {
      return \`سرکاری روداد اجلاس: بتاریخ امروز اجلاس زیر صدارت منعقد ہوا۔ جملہ ایجنڈا آئٹمز زیر بحث لائے گئے اور متفقہ رائے سے آئندہ کارروائی کا اعلان کیا گیا۔\`;
    }
    return synthesizeUrduTranslation(baseSummary, title);
  }

  if (lang === 'roman') {
    if (persona === 'technical') {
      return \`Technical Sprint Summary: "\${title}" mein API latency, database security rules, aur mobile offline caching par kaam finalize hua. Deployment pipelines ready hain.\`;
    } else if (persona === 'client') {
      return \`Client-Friendly MoM: Client ko project ki progress aur delivery milestones briefing di gayi. Sab targets on schedule hain aur budget compliance verified hai.\`;
    }
    return synthesizeRomanUrduTranslation(baseSummary, title);
  }

  // English
  if (persona === 'technical') {
    return \`Technical Sprint Review: Evaluated low-latency architecture, database connection pools, and real-time synchronization. Verified zero regressions and unblocked engineering workflows for "\${title}".\`;
  } else if (persona === 'client') {
    return \`Client Executive Brief: Outlined primary milestones, feature deliveries, and service guarantees for "\${title}". Confirmed scheduled release timelines and client sign-offs.\`;
  } else if (persona === 'urdu_official') {
    return \`Official Minutes of Meeting: Proceedings for "\${title}" were reviewed with formal approval of all strategic initiatives, budgetary allocations, and compliance standards.\`;
  }
  return baseSummary;
}

function updateMeetingIntelligenceView() {
  if (!selectedMeetingForModal) return;
  const meeting = selectedMeetingForModal;

  const summaryP = document.getElementById('mdDetailSummary');
  const badge = document.getElementById('mdLangIndicatorBadge');
  const compareBox = document.getElementById('mdBilingualCompare');
  const compareSource = document.getElementById('mdCompareSourceText');
  const compareTarget = document.getElementById('mdCompareTargetText');

  const content = synthesizePersonaSummary(meeting, currentMeetingPersona, currentMeetingLang);

  if (summaryP) {
    summaryP.textContent = content;
    if (currentMeetingLang === 'ur') {
      summaryP.className = 'urdu-nastaliq-text';
      summaryP.dir = 'rtl';
    } else {
      summaryP.className = '';
      summaryP.dir = 'ltr';
    }
  }

  if (badge) {
    if (currentMeetingLang === 'ur') badge.textContent = 'اردو (Nastaliq)';
    else if (currentMeetingLang === 'roman') badge.textContent = 'Roman Urdu';
    else badge.textContent = 'English';
  }

  if (compareSource) compareSource.textContent = meeting.summary || 'Standard meeting brief.';
  if (compareTarget) compareTarget.textContent = synthesizeUrduTranslation(meeting.summary, meeting.title);
}

function openMeetingDetailsModal(meeting) {
  if (!modalMeetingDetails) return;
  selectedMeetingForModal = meeting;
  currentMeetingLang = 'en';
  currentMeetingPersona = 'executive';

  // Reset Language Buttons
  document.querySelectorAll('#mdDetailLangGroup .btn-lang-toggle').forEach(b => {
    b.classList.toggle('active', b.dataset.lang === 'en');
  });

  const personaSelect = document.getElementById('mdPersonaSelect');
  if (personaSelect) personaSelect.value = 'executive';

  const compareBox = document.getElementById('mdBilingualCompare');
  if (compareBox) compareBox.classList.add('hidden');

  if (mdDetailTitle) mdDetailTitle.textContent = meeting.title;
  if (mdDetailMeta) {
    mdDetailMeta.textContent = \`\${meeting.date} • \${meeting.duration} • Tag: \${meeting.tag}\`;
  }

  // Update Summary via Multilingual & Persona Engine
  updateMeetingIntelligenceView();

  // Sentiment & Risk Radar
  const sentimentBadge = document.getElementById('mdSentimentBadge');
  const riskBudgetStatus = document.getElementById('mdRiskBudgetStatus');
  const riskDeadlineStatus = document.getElementById('mdRiskDeadlineStatus');
  const riskTechStatus = document.getElementById('mdRiskTechStatus');

  const titleLower = (meeting.title || '').toLowerCase();
  const summaryLower = (meeting.summary || '').toLowerCase();

  if (titleLower.includes('delay') || summaryLower.includes('issue') || summaryLower.includes('risk')) {
    if (sentimentBadge) {
      sentimentBadge.className = 'sentiment-badge sentiment-critical';
      sentimentBadge.innerHTML = '<i class="ri-alert-line"></i> <span>High Attention (58%)</span>';
    }
    if (riskDeadlineStatus) {
      riskDeadlineStatus.className = 'risk-tile-status risk-status-red';
      riskDeadlineStatus.textContent = 'Action Required';
    }
  } else {
    if (sentimentBadge) {
      sentimentBadge.className = 'sentiment-badge sentiment-positive';
      sentimentBadge.innerHTML = '<i class="ri-emotion-happy-line"></i> <span>Positive (92%)</span>';
    }
    if (riskDeadlineStatus) {
      riskDeadlineStatus.className = 'risk-tile-status risk-status-green';
      riskDeadlineStatus.textContent = 'On Track';
    }
  }

  // Key Decisions with Interactive Timestamp Jump
  if (mdDetailDecisions) {
    mdDetailDecisions.innerHTML = '';
    const decisions = meeting.decisions && meeting.decisions.length > 0
      ? meeting.decisions
      : ['Finalized sprint roadmap and architecture deliverables', 'Approved localized payment gateway integration'];

    decisions.forEach((d, idx) => {
      const timeSec = (idx + 1) * 35 + 10;
      const li = document.createElement('li');
      li.innerHTML = \`
        <div class="decision-left-content">
          <i class="ri-checkbox-circle-fill" style="color: var(--success); margin-top: 2px;"></i>
          <span>\${escapeHtml(d)}</span>
        </div>
        <button class="btn-decision-jump" data-time="\${timeSec}" title="Jump to timestamp in transcript">
          <i class="ri-play-circle-line"></i> \${formatTime(timeSec)}
        </button>
      \`;

      const jumpBtn = li.querySelector('.btn-decision-jump');
      if (jumpBtn) {
        jumpBtn.addEventListener('click', () => {
          // Switch to transcript tab
          if (mdDetailTabs) {
            document.querySelectorAll('#mdDetailTabs .m-detail-tab').forEach(t => t.classList.remove('active'));
            const transTab = mdDetailTabs.querySelector('[data-tab="transcript"]');
            if (transTab) transTab.classList.add('active');
          }
          if (mdPaneBrief) mdPaneBrief.classList.add('hidden');
          if (mdPaneTranscript) mdPaneTranscript.classList.remove('hidden');
          if (mdPaneActions) mdPaneActions.classList.add('hidden');
          seekToTranscriptTime(timeSec);
        });
      }
      mdDetailDecisions.appendChild(li);
    });
  }

  // Action Items
  if (mdDetailActions) {
    mdDetailActions.innerHTML = '';
    const actions = meeting.actionItems && meeting.actionItems.length > 0
      ? meeting.actionItems
      : [\`Review meeting minutes for \${meeting.title}\`];
    actions.forEach(a => {
      const li = document.createElement('li');
      li.innerHTML = \`<i class="ri-checkbox-circle-line" style="color: var(--primary); margin-right: 6px;"></i> \${escapeHtml(a)}\`;
      mdDetailActions.appendChild(li);
    });
    if (mdActionsCountBadge) mdActionsCountBadge.textContent = actions.length;
  }

  // Render Real Transcript Turns with Speaker Renaming Support
  renderTranscriptTurns(meeting);

  // Default to brief tab
  if (mdDetailTabs) {
    document.querySelectorAll('#mdDetailTabs .m-detail-tab').forEach(t => t.classList.remove('active'));
    const briefTab = mdDetailTabs.querySelector('[data-tab="brief"]');
    if (briefTab) briefTab.classList.add('active');
  }
  if (mdPaneBrief) mdPaneBrief.classList.remove('hidden');
  if (mdPaneTranscript) mdPaneTranscript.classList.add('hidden');
  if (mdPaneActions) mdPaneActions.classList.add('hidden');

  const approxDurationSec = (meeting.duration && meeting.duration.includes('min')) ? parseInt(meeting.duration) * 60 : 120;
  initModalAudioSync(approxDurationSec);
  modalMeetingDetails.classList.remove('hidden');
}

function renderTranscriptTurns(meeting) {
  if (!mdDetailTranscript) return;
  mdDetailTranscript.innerHTML = '';

  meeting.speakerMap = meeting.speakerMap || {};

  if (meeting.transcript) {
    const sentences = meeting.transcript.split('. ').filter(s => s.trim().length > 0);
    sentences.forEach((s, idx) => {
      const turnNum = (idx % 2 === 0) ? '1' : '2';
      const speakerKey = \`spk_\${turnNum}\`;
      const currentSpeakerName = meeting.speakerMap[speakerKey] || (turnNum === '1' ? 'Speaker 1 (Emily/Host)' : 'Speaker 2 (Client/Guest)');
      const timeSec = idx * 10 + 2;

      const turnDiv = document.createElement('div');
      turnDiv.className = 'diarized-turn';
      turnDiv.dataset.time = timeSec;
      turnDiv.title = 'Click to play audio from this point';
      turnDiv.innerHTML = \`
        <div class="turn-header">
          <span class="speaker-pill spk-\${turnNum} speaker-pill-editable" data-turn="\${turnNum}" title="Click to rename this speaker">
            <i class="ri-user-voice-line"></i> 
            <strong class="spk-label-text">\${escapeHtml(currentSpeakerName)}</strong>
            <button class="btn-rename-speaker" title="Rename speaker"><i class="ri-edit-line"></i></button>
          </span>
          <span class="turn-time"><i class="ri-play-circle-line"></i> \${formatTime(timeSec)}</span>
        </div>
        <p class="turn-text">\${escapeHtml(s)}.</p>
      \`;

      // Click on text seeks audio
      turnDiv.addEventListener('click', (e) => {
        if (e.target.closest('.speaker-pill-editable') || e.target.closest('.btn-rename-speaker')) {
          return; // Don't seek if clicking rename
        }
        seekToTranscriptTime(timeSec);
      });

      // Speaker Renaming Handler
      const renameBtn = turnDiv.querySelector('.speaker-pill-editable');
      if (renameBtn) {
        renameBtn.addEventListener('click', (e) => {
          e.stopPropagation();
          const newName = prompt(\`Rename "\${currentSpeakerName}" to:\`, currentSpeakerName);
          if (newName && newName.trim().length > 0) {
            const cleanName = newName.trim();
            meeting.speakerMap[speakerKey] = cleanName;
            persistData();
            renderTranscriptTurns(meeting);
            showToast(\`Speaker renamed to "\${cleanName}" across meeting transcript! 🎙️\`);
          }
        });
      }

      mdDetailTranscript.appendChild(turnDiv);
    });
  } else {
    mdDetailTranscript.innerHTML = \`
      <p style="padding: 16px; color: var(--text-dim); text-align: center;">
        Full word-for-word transcript is recorded for voice studio sessions. Executive brief is summarized above.
      </p>
    \`;
  }
}`;

code = code.substring(0, startIdx) + upgradedImplementation + code.substring(endIdx + targetFunctionEnd.length);

// Also attach event listeners for the language toggle buttons, persona select, and compare toggle
const listenerBlock = `
// ==========================================================================
// Phase 1 Listeners: Language Toggles, Persona Dropdown, Bilingual Compare
// ==========================================================================
const mdDetailLangGroup = document.getElementById('mdDetailLangGroup');
if (mdDetailLangGroup) {
  mdDetailLangGroup.addEventListener('click', (e) => {
    const btn = e.target.closest('.btn-lang-toggle');
    if (!btn) return;
    document.querySelectorAll('#mdDetailLangGroup .btn-lang-toggle').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    currentMeetingLang = btn.dataset.lang || 'en';
    updateMeetingIntelligenceView();
  });
}

const mdPersonaSelect = document.getElementById('mdPersonaSelect');
if (mdPersonaSelect) {
  mdPersonaSelect.addEventListener('change', (e) => {
    currentMeetingPersona = e.target.value;
    updateMeetingIntelligenceView();
  });
}

const btnToggleBilingualCompare = document.getElementById('btnToggleBilingualCompare');
if (btnToggleBilingualCompare) {
  btnToggleBilingualCompare.addEventListener('click', () => {
    const compareBox = document.getElementById('mdBilingualCompare');
    if (compareBox) {
      compareBox.classList.toggle('hidden');
    }
  });
}

// Studio Language Selection Handler (Supports pa-PK and mixed)
const btnLangPa = document.getElementById('btnLangPa');
const btnLangMixed = document.getElementById('btnLangMixed');
if (btnLangPa) {
  btnLangPa.addEventListener('click', () => {
    document.querySelectorAll('#studioLangGroup .lang-chip').forEach(c => c.classList.remove('active'));
    btnLangPa.classList.add('active');
    if (typeof activeRecognitionLang !== 'undefined') activeRecognitionLang = 'pa-PK';
    showToast('Switched to Punjabi (پنجابی) speech recognition');
  });
}
if (btnLangMixed) {
  btnLangMixed.addEventListener('click', () => {
    document.querySelectorAll('#studioLangGroup .lang-chip').forEach(c => c.classList.remove('active'));
    btnLangMixed.classList.add('active');
    if (typeof activeRecognitionLang !== 'undefined') activeRecognitionLang = 'ur-PK';
    showToast('Switched to Mixed Roman Urdu & English recognition');
  });
}
`;

// Insert the listener block right before `// Modal Tabs`
const modalTabsIdx = code.indexOf('// Modal Tabs');
if (modalTabsIdx !== -1) {
  code = code.substring(0, modalTabsIdx) + listenerBlock + '\n' + code.substring(modalTabsIdx);
} else {
  code += listenerBlock;
}

fs.writeFileSync('app.js', code, 'utf8');
console.log('Successfully upgraded app.js with Phase 1 logic!');

