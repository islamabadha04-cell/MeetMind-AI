// ==========================================================================
// MeetMind AI — Your Intelligent Meeting Assistant (2027)
// Universal Logic: Desktop & Mobile Apps, Backend APIs, PWA, AI RAG
// ==========================================================================

const API_BASE_URL = 'http://127.0.0.1:8000/api/v1';

// Seed Initial Meetings Data from Reference UI
const INITIAL_MEETINGS = [
  {
    id: 1,
    title: 'Project Alpha Discussion',
    date: 'Today, 10:30 AM',
    duration: '22 min',
    tag: 'Work',
    tagClass: 'tag-work',
    summary: 'The meeting focused on the Project Alpha timeline, finalized new low-latency audio capture specs, and agreed to launch sprint beta.',
    decisions: ['Approved the new design direction', 'Set Q2 launch target', 'Allocated budget for marketing'],
    actionItems: ['Design mockups - Sarah (Apr 30)', 'API integration - Ali (May 5)', 'Marketing plan - John (May 10)']
  },
  {
    id: 2,
    title: 'Client Call - Acme Corp',
    date: 'Yesterday, 2:15 PM',
    duration: '45 min',
    tag: 'Client',
    tagClass: 'tag-client',
    summary: 'Reviewed client requirements for automated transcription, security compliance, and custom workspace data isolation.',
    decisions: ['Agreed on SOC2 compliance timeline', 'Provided custom export options in PDF/DOCX'],
    actionItems: ['Send contract draft - Legal (May 2)', 'Follow up on technical onboarding - Ali (May 4)']
  },
  {
    id: 3,
    title: 'Team Standup',
    date: 'Apr 24, 2025',
    duration: '18 min',
    tag: 'Team',
    tagClass: 'tag-team',
    summary: 'Daily progress check-in across engineering and design sprints. All blockers resolved.',
    decisions: ['Merged backend PRs into staging', 'Scheduled design system sign-off'],
    actionItems: ['Code review for PWA service worker - Lead Dev']
  },
  {
    id: 4,
    title: 'Product Roadmap',
    date: 'Apr 22, 2025',
    duration: '52 min',
    tag: 'Product',
    tagClass: 'tag-product',
    summary: 'Quarterly planning session prioritizing AI voice note search, multi-language speech diarization, and team analytics.',
    decisions: ['Prioritized Urdu and English bilingual transcription', 'Approved mobile PWA packaging'],
    actionItems: ['Prepare presentation for stakeholders - Product Lead']
  }
];

let meetings = [...INITIAL_MEETINGS];
let isRecording = true;
let recSeconds = 754; // 00:12:34
let recTimerInterval = null;
let deferredPrompt = null;

// DOM Elements
const desktopAppView = document.getElementById('desktopAppView');
const mobileShowcaseView = document.getElementById('mobileShowcaseView');
const btnViewDesktop = document.getElementById('btnViewDesktop');
const btnViewMobileShowcase = document.getElementById('btnViewMobileShowcase');
const btnViewMobilePhone = document.getElementById('btnViewMobilePhone');
const themeToggleBtn = document.getElementById('themeToggleBtn');
const deskThemeBtn = document.getElementById('deskThemeBtn');
const themeIcon = document.getElementById('themeIcon');
const installMobileBtn = document.getElementById('installMobileBtn');
const modalInstallPWA = document.getElementById('modalInstallPWA');
const closeInstallModal = document.getElementById('closeInstallModal');
const copyUrlBtn = document.getElementById('copyUrlBtn');
const universalToast = document.getElementById('universalToast');
const uToastMsg = document.getElementById('uToastMsg');

// Desktop Elements
const desktopMeetingsList = document.getElementById('desktopMeetingsList');
const desktopSearchInput = document.getElementById('desktopSearchInput');
const deskStartRecordCard = document.getElementById('deskStartRecordCard');
const deskRecordBtn = document.getElementById('deskRecordBtn');

// Mobile Elements
const mRecentMeetingsList = document.getElementById('mRecentMeetingsList');
const mWaveContainer = document.getElementById('mWaveContainer');
const mRecTimer = document.getElementById('mRecTimer');
const mBtnPauseRecord = document.getElementById('mBtnPauseRecord');
const mPauseIcon = document.getElementById('mPauseIcon');
const mBtnEndRecording = document.getElementById('mBtnEndRecording');
const mChatMessagesList = document.getElementById('mChatMessagesList');
const mChatInput = document.getElementById('mChatInput');
const mChatSendBtn = document.getElementById('mChatSendBtn');
const mFollowupChips = document.getElementById('mFollowupChips');
const mSummaryTabContent = document.getElementById('mSummaryTabContent');

// Toast Notification
function showToast(msg) {
  uToastMsg.textContent = msg;
  universalToast.classList.remove('hidden');
  setTimeout(() => {
    universalToast.classList.add('hidden');
  }, 2400);
}

// ==========================================================================
// Theme Toggling (Light / Dark Mode)
// ==========================================================================
function toggleTheme() {
  const current = document.documentElement.getAttribute('data-theme') || 'light';
  const target = current === 'light' ? 'dark' : 'light';
  document.documentElement.setAttribute('data-theme', target);
  localStorage.setItem('meetmind_theme', target);

  if (target === 'dark') {
    themeIcon.className = 'ri-sun-line';
    showToast('Dark Mode Activated 🌙');
  } else {
    themeIcon.className = 'ri-moon-line';
    showToast('Light Mode Activated ☀️');
  }
}

themeToggleBtn.addEventListener('click', toggleTheme);
if (deskThemeBtn) deskThemeBtn.addEventListener('click', toggleTheme);

// Initialize saved theme
const savedTheme = localStorage.getItem('meetmind_theme');
if (savedTheme) {
  document.documentElement.setAttribute('data-theme', savedTheme);
  themeIcon.className = savedTheme === 'dark' ? 'ri-sun-line' : 'ri-moon-line';
}

// ==========================================================================
// View Mode Switcher (Desktop App vs 5-Screen Mobile Showcase)
// ==========================================================================
function switchViewMode(mode) {
  document.querySelectorAll('.u-btn').forEach(b => b.classList.remove('active'));

  if (mode === 'desktop') {
    btnViewDesktop.classList.add('active');
    desktopAppView.style.display = 'grid';
    mobileShowcaseView.classList.add('hidden');
    showToast('Desktop Application View');
  } else if (mode === 'mobile-showcase') {
    btnViewMobileShowcase.classList.add('active');
    desktopAppView.style.display = 'none';
    mobileShowcaseView.classList.remove('hidden');
    showToast('5-Screen Mobile Showcase View');
  } else if (mode === 'mobile-phone') {
    btnViewMobilePhone.classList.add('active');
    desktopAppView.style.display = 'none';
    mobileShowcaseView.classList.remove('hidden');
    // Scroll smoothly to Screen 2 (Home Dashboard)
    const phones = document.querySelectorAll('.mockup-phone');
    if (phones[1]) phones[1].scrollIntoView({ behavior: 'smooth', block: 'center' });
    showToast('Interactive Mobile Screen Focused 📱');
  }
}

btnViewDesktop.addEventListener('click', () => switchViewMode('desktop'));
btnViewMobileShowcase.addEventListener('click', () => switchViewMode('mobile-showcase'));
btnViewMobilePhone.addEventListener('click', () => switchViewMode('mobile-phone'));

// ==========================================================================
// Render Recent Meetings (Desktop & Mobile)
// ==========================================================================
function renderMeetings(filterText = '') {
  const filtered = meetings.filter(m => {
    if (!filterText) return true;
    return m.title.toLowerCase().includes(filterText.toLowerCase()) || 
           m.summary.toLowerCase().includes(filterText.toLowerCase());
  });

  // Render Desktop List
  desktopMeetingsList.innerHTML = '';
  filtered.forEach(m => {
    const row = document.createElement('div');
    row.className = 'meeting-row-card';
    row.innerHTML = `
      <div class="meeting-row-left">
        <div class="meeting-row-icon">
          <i class="ri-voiceprint-line"></i>
        </div>
        <div class="meeting-row-info">
          <h4>${escapeHtml(m.title)}</h4>
          <p class="meeting-row-meta">${m.date} • ${m.duration}</p>
        </div>
      </div>
      <div class="meeting-row-right">
        <span class="badge-tag ${m.tagClass}">${m.tag}</span>
        <span class="badge-summary-ready"><i class="ri-checkbox-circle-fill"></i> Summary Ready</span>
      </div>
    `;
    row.addEventListener('click', () => {
      showToast(`Viewing "${m.title}" Summary`);
    });
    desktopMeetingsList.appendChild(row);
  });

  // Render Mobile List
  mRecentMeetingsList.innerHTML = '';
  filtered.slice(0, 3).forEach(m => {
    const mCard = document.createElement('div');
    mCard.style.cssText = 'background: var(--bg-surface); padding: 10px 12px; border-radius: 12px; display: flex; align-items: center; justify-content: space-between; cursor: pointer;';
    mCard.innerHTML = `
      <div style="display: flex; align-items: center; gap: 10px;">
        <i class="ri-voiceprint-fill" style="color: var(--primary); font-size: 16px;"></i>
        <div>
          <h5 style="font-size: 12.5px; font-weight: 700;">${escapeHtml(m.title)}</h5>
          <span style="font-size: 10px; color: var(--text-dim);">${m.date} • ${m.duration}</span>
        </div>
      </div>
      <i class="ri-arrow-right-s-line" style="color: var(--text-dim);"></i>
    `;
    mCard.addEventListener('click', () => {
      switchViewMode('mobile-showcase');
      const phones = document.querySelectorAll('.mockup-phone');
      if (phones[3]) phones[3].scrollIntoView({ behavior: 'smooth', block: 'center' });
    });
    mRecentMeetingsList.appendChild(mCard);
  });
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text || '';
  return div.innerHTML;
}

// Search Filter Listener
desktopSearchInput.addEventListener('input', (e) => {
  renderMeetings(e.target.value.trim());
});

// Shortcut ⌘K / Ctrl+K
window.addEventListener('keydown', (e) => {
  if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
    e.preventDefault();
    desktopSearchInput.focus();
  }
});

// ==========================================================================
// Live Animated Audio Waveform & Timer
// ==========================================================================
const NUM_WAVE_BARS = 32;
let waveBars = [];

function initMobileWaveform() {
  mWaveContainer.innerHTML = '';
  waveBars = [];
  for (let i = 0; i < NUM_WAVE_BARS; i++) {
    const bar = document.createElement('div');
    bar.className = 'm-wave-bar';
    const norm = Math.sin((i / (NUM_WAVE_BARS - 1)) * Math.PI);
    const h = Math.max(8, Math.floor(norm * 85));
    bar.style.height = `${h}px`;
    mWaveContainer.appendChild(bar);
    waveBars.push({ el: bar, base: h });
  }
}

function animateWaveform() {
  if (!isRecording) return;
  const time = Date.now() / 140;

  waveBars.forEach((b, i) => {
    const norm = Math.sin((i / (NUM_WAVE_BARS - 1)) * Math.PI);
    const osc = Math.sin(time + i * 0.4) * 20 + Math.cos(time * 0.7 + i * 0.2) * 12;
    const h = Math.max(8, Math.min(100, Math.floor(norm * 75 + osc)));
    b.el.style.height = `${h}px`;
  });

  requestAnimationFrame(animateWaveform);
}

function formatTimer(totalSec) {
  const hrs = String(Math.floor(totalSec / 3600)).padStart(2, '0');
  const mins = String(Math.floor((totalSec % 3600) / 60)).padStart(2, '0');
  const secs = String(totalSec % 60).padStart(2, '0');
  return `${hrs}:${mins}:${secs}`;
}

function startTimer() {
  if (recTimerInterval) clearInterval(recTimerInterval);
  recTimerInterval = setInterval(() => {
    if (isRecording) {
      recSeconds++;
      mRecTimer.textContent = formatTimer(recSeconds);
    }
  }, 1000);
}

// Pause / Resume Recording
mBtnPauseRecord.addEventListener('click', () => {
  isRecording = !isRecording;
  if (isRecording) {
    mPauseIcon.className = 'ri-pause-line';
    animateWaveform();
    showToast('Recording resumed 🎙️');
  } else {
    mPauseIcon.className = 'ri-play-fill';
    showToast('Recording paused ⏸️');
  }
});

// End Recording Action
mBtnEndRecording.addEventListener('click', () => {
  showToast('Meeting ended! Generating AI Summary & Action Items... ✨');
  const newMeeting = {
    id: Date.now(),
    title: 'Strategy & Execution Sync',
    date: 'Just now',
    duration: formatTimer(recSeconds),
    tag: 'Work',
    tagClass: 'tag-work',
    summary: 'Executive strategy sync finalizing deployment architecture, security isolation, and Q2 launch deliverables.',
    decisions: ['Approved PWA mobile release', 'Scheduled QA testing for speech diarization'],
    actionItems: ['Deploy production build - Team', 'Share feedback - Ali']
  };
  meetings.unshift(newMeeting);
  renderMeetings();

  // Scroll to summary screen in mobile showcase
  const phones = document.querySelectorAll('.mockup-phone');
  if (phones[3]) phones[3].scrollIntoView({ behavior: 'smooth', block: 'center' });
});

// Desktop Start Record
deskStartRecordCard.addEventListener('click', () => {
  switchViewMode('mobile-showcase');
  const phones = document.querySelectorAll('.mockup-phone');
  if (phones[2]) phones[2].scrollIntoView({ behavior: 'smooth', block: 'center' });
});

if (deskRecordBtn) {
  deskRecordBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    deskStartRecordCard.click();
  });
}

// Mobile Splash "Get Started"
document.getElementById('btnSplashStart').addEventListener('click', () => {
  const phones = document.querySelectorAll('.mockup-phone');
  if (phones[1]) phones[1].scrollIntoView({ behavior: 'smooth', block: 'center' });
});

// Mobile Bottom Mic button
document.getElementById('mBottomMicBtn').addEventListener('click', () => {
  const phones = document.querySelectorAll('.mockup-phone');
  if (phones[2]) phones[2].scrollIntoView({ behavior: 'smooth', block: 'center' });
});

// ==========================================================================
// Ask AI (RAG Chat with Meetings)
// ==========================================================================
function sendChatMessage(text) {
  if (!text || !text.trim()) return;

  // Add user bubble
  const userBubble = document.createElement('div');
  userBubble.className = 'chat-bubble user-bubble';
  userBubble.innerHTML = `<p>${escapeHtml(text)}</p>`;
  mChatMessagesList.appendChild(userBubble);
  mChatMessagesList.scrollTop = mChatMessagesList.scrollHeight;

  // Simulate or Call Backend AI
  setTimeout(() => {
    const aiBubble = document.createElement('div');
    aiBubble.className = 'chat-bubble ai-bubble';
    
    // Check keyword
    const lower = text.toLowerCase();
    let reply = '';
    let citation = 'Project Alpha Discussion • 10:32 AM';

    if (lower.includes('decision') || lower.includes('main')) {
      reply = `Here are the key decisions from your meetings:
      <ol style="margin-top: 4px; padding-left: 16px;">
        <li>Approved the new design direction.</li>
        <li>Set Q2 launch target.</li>
        <li>Allocated budget for marketing.</li>
      </ol>`;
    } else if (lower.includes('next step') || lower.includes('step')) {
      reply = `The immediate next steps identified are:
      <ol style="margin-top: 4px; padding-left: 16px;">
        <li>Sarah to deliver final design mockups by Apr 30.</li>
        <li>Ali to finalize backend API integration by May 5.</li>
      </ol>`;
      citation = 'Project Alpha Discussion • 10:45 AM';
    } else if (lower.includes('deadline')) {
      reply = `Upcoming deadlines:
      <ul style="margin-top: 4px; padding-left: 16px;">
        <li><strong>Apr 30</strong>: Design mockups</li>
        <li><strong>May 5</strong>: API integration</li>
        <li><strong>May 10</strong>: Marketing plan</li>
      </ul>`;
      citation = 'Team Standup • 10:48 AM';
    } else {
      reply = `Based on your meeting history, "${escapeHtml(text)}" was discussed in <strong>Project Alpha Discussion</strong> with unanimous agreement from the leadership team.`;
    }

    aiBubble.innerHTML = `
      <div class="ai-header-badge"><i class="ri-sparkling-fill"></i> MeetMind AI</div>
      <p>${reply}</p>
      <div class="chat-citation">
        <i class="ri-file-text-line"></i> Source: ${citation}
      </div>
    `;
    mChatMessagesList.appendChild(aiBubble);
    mChatMessagesList.scrollTop = mChatMessagesList.scrollHeight;
  }, 450);
}

mChatSendBtn.addEventListener('click', () => {
  const val = mChatInput.value.trim();
  if (val) {
    sendChatMessage(val);
    mChatInput.value = '';
  }
});

mChatInput.addEventListener('keydown', (e) => {
  if (e.key === 'Enter') {
    mChatSendBtn.click();
  }
});

// Follow-up Chips
mFollowupChips.addEventListener('click', (e) => {
  const chip = e.target.closest('.f-chip');
  if (chip) {
    sendChatMessage(chip.textContent);
  }
});

// ==========================================================================
// AI Summary Screen Tabs
// ==========================================================================
document.querySelectorAll('.m-sum-tab').forEach(tab => {
  tab.addEventListener('click', () => {
    document.querySelectorAll('.m-sum-tab').forEach(t => t.classList.remove('active'));
    tab.classList.add('active');
    const type = tab.dataset.tab;

    if (type === 'summary') {
      mSummaryTabContent.innerHTML = `
        <div class="m-summary-section">
          <h5>Executive Summary</h5>
          <p>The meeting focused on the Project Alpha timeline, finalized new low-latency audio capture specs, and agreed to launch sprint beta.</p>
        </div>
        <div class="m-summary-section">
          <h5>Key Decisions</h5>
          <ul class="m-decisions-list">
            <li>Approved the new design direction.</li>
            <li>Set Q2 launch target.</li>
            <li>Allocated budget for marketing.</li>
          </ul>
        </div>
        <div class="m-summary-section">
          <h5>Action Items</h5>
          <div class="m-action-check-list">
            <label class="m-check-item"><input type="checkbox" checked> <span>Design mockups - Sarah (Apr 30)</span></label>
            <label class="m-check-item"><input type="checkbox"> <span>API integration - Ali (May 5)</span></label>
            <label class="m-check-item"><input type="checkbox"> <span>Marketing plan - John (May 10)</span></label>
          </div>
        </div>
      `;
    } else if (type === 'transcript') {
      mSummaryTabContent.innerHTML = `
        <div class="m-summary-section">
          <h5>Timestamped Transcript</h5>
          <div style="font-size: 11.5px; line-height: 1.6; color: var(--text-muted); display: flex; flex-direction: column; gap: 8px;">
            <p><strong>[00:00 - 04:12] Ali:</strong> Good morning everyone, let us review the Project Alpha deliverables and audio transcription latency.</p>
            <p><strong>[04:13 - 10:45] Sarah:</strong> The UI mockups with purple/lavender gradients and rounded cards are fully finalized.</p>
            <p><strong>[10:46 - 22:00] John:</strong> Excellent. Backend APIs and PWA mobile manifests are ready for deployment.</p>
          </div>
        </div>
      `;
    } else if (type === 'tasks') {
      mSummaryTabContent.innerHTML = `
        <div class="m-summary-section">
          <h5>Extracted Tasks (3)</h5>
          <div class="m-action-check-list">
            <label class="m-check-item"><input type="checkbox" checked> <span>Design mockups - Sarah (Apr 30) • High</span></label>
            <label class="m-check-item"><input type="checkbox"> <span>API integration - Ali (May 5) • High</span></label>
            <label class="m-check-item"><input type="checkbox"> <span>Marketing plan - John (May 10) • Medium</span></label>
          </div>
        </div>
      `;
    }
  });
});

// Export Summary Button
document.getElementById('mBtnExportSummary').addEventListener('click', () => {
  const content = `MEETMIND AI — MEETING SUMMARY\n\nTitle: Project Alpha Discussion\nDate: Today, 10:30 AM\n\nExecutive Summary:\nThe meeting focused on the Project Alpha timeline, finalized new audio capture specs, and agreed to launch sprint beta.\n\nKey Decisions:\n1. Approved the new design direction.\n2. Set Q2 launch target.\n3. Allocated budget for marketing.\n\nAction Items:\n- Design mockups (Sarah - Apr 30)\n- API integration (Ali - May 5)\n- Marketing plan (John - May 10)`;
  navigator.clipboard.writeText(content).then(() => {
    showToast('Meeting Summary copied to clipboard! 📋');
  });
});

// ==========================================================================
// PWA Installation & QR Modal
// ==========================================================================
installMobileBtn.addEventListener('click', () => {
  modalInstallPWA.classList.remove('hidden');
});

closeInstallModal.addEventListener('click', () => {
  modalInstallPWA.classList.add('hidden');
});

modalInstallPWA.addEventListener('click', (e) => {
  if (e.target === modalInstallPWA) {
    modalInstallPWA.classList.add('hidden');
  }
});

copyUrlBtn.addEventListener('click', () => {
  const url = document.getElementById('localNetworkUrl').textContent;
  navigator.clipboard.writeText(url).then(() => {
    showToast('Network URL copied! Open in your phone browser 📲');
  });
});

// PWA Install Prompt Capture
window.addEventListener('beforeinstallprompt', (e) => {
  e.preventDefault();
  deferredPrompt = e;
  installMobileBtn.style.display = 'flex';
});

document.getElementById('btnInstallSelf').addEventListener('click', async () => {
  if (deferredPrompt) {
    deferredPrompt.prompt();
    const { outcome } = await deferredPrompt.userChoice;
    if (outcome === 'accepted') {
      showToast('MeetMind AI Installed! Check your home screen 📱');
    }
    deferredPrompt = null;
    modalInstallPWA.classList.add('hidden');
  } else {
    showToast('Please open http://192.168.140.112:8080 on your phone to install!');
  }
});

// Register Service Worker
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('./sw.js').then(() => {
    console.log('[PWA] Service Worker active');
  }).catch((err) => {
    console.log('[PWA] SW register:', err);
  });
}

// ==========================================================================
// Initial Execution
// ==========================================================================
renderMeetings();
initMobileWaveform();
animateWaveform();
startTimer();
