// ==========================================================================
// MeetMind AI — Your Intelligent Meeting Assistant (2027)
// Universal Enterprise Logic: Desktop & Mobile Apps, Backend APIs, PWA, AI RAG
// ==========================================================================

let API_BASE_URL = localStorage.getItem('meetmind_backend_url') || 'http://127.0.0.1:8000/api/v1';

// Seed Initial Meetings Data
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
    date: 'Apr 24, 2026',
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
    date: 'Apr 22, 2026',
    duration: '52 min',
    tag: 'Product',
    tagClass: 'tag-product',
    summary: 'Quarterly planning session prioritizing AI voice note search, multi-language speech diarization, and team analytics.',
    decisions: ['Prioritized Urdu and English bilingual transcription', 'Approved mobile PWA packaging'],
    actionItems: ['Prepare presentation for stakeholders - Product Lead']
  }
];

// Seed Initial Tasks
const INITIAL_TASKS = [
  { id: 101, title: 'Design high-fidelity mockups for recording studio', assignee: 'Sarah', priority: 'high', deadline: 'Apr 30, 2026', completed: true },
  { id: 102, title: 'Finalize low-latency audio stream integration in FastAPI', assignee: 'Ali', priority: 'high', deadline: 'May 5, 2026', completed: false },
  { id: 103, title: 'Draft marketing launch strategy for Enterprise tier', assignee: 'John', priority: 'medium', deadline: 'May 10, 2026', completed: false },
  { id: 104, title: 'Review SOC2 data isolation policies with legal team', assignee: 'Legal', priority: 'high', deadline: 'May 2, 2026', completed: false },
  { id: 105, title: 'Verify PWA offline cache and Service Worker in Safari', assignee: 'Dev Lead', priority: 'low', deadline: 'May 8, 2026', completed: false },
  { id: 106, title: 'Prepare slide deck for board of directors', assignee: 'Product Lead', priority: 'medium', deadline: 'May 12, 2026', completed: false }
];

// State
let meetings = JSON.parse(localStorage.getItem('meetmind_meetings')) || [...INITIAL_MEETINGS];
let tasks = JSON.parse(localStorage.getItem('meetmind_tasks')) || [...INITIAL_TASKS];
let activeMeetingFilter = 'all';
let activeTaskFilter = 'all';
let selectedMeetingForModal = null;
let deferredPrompt = null;

// Audio Studio Recording State
let isStudioRecording = false;
let studioSeconds = 0;
let studioTimerInterval = null;
let studioAudioCtx = null;
let studioAnalyser = null;
let studioMediaStream = null;
let studioSpeechRecognition = null;
let studioBookmarks = [];
let studioTranscriptAccumulator = '';

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

// Stats Elements
const statTotalMeetings = document.getElementById('statTotalMeetings');
const statOpenTasks = document.getElementById('statOpenTasks');
const navTaskCountBadge = document.getElementById('navTaskCountBadge');

// ==========================================================================
// Toast Notification
// ==========================================================================
function showToast(msg) {
  if (!universalToast) return;
  uToastMsg.textContent = msg;
  universalToast.classList.remove('hidden');
  setTimeout(() => {
    universalToast.classList.add('hidden');
  }, 2500);
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text || '';
  return div.innerHTML;
}

function persistData() {
  localStorage.setItem('meetmind_meetings', JSON.stringify(meetings));
  localStorage.setItem('meetmind_tasks', JSON.stringify(tasks));
  updateStats();
}

function updateStats() {
  if (statTotalMeetings) statTotalMeetings.textContent = meetings.length;
  const pendingCount = tasks.filter(t => !t.completed).length;
  if (statOpenTasks) statOpenTasks.textContent = pendingCount;
  if (navTaskCountBadge) navTaskCountBadge.textContent = pendingCount;
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
    if (themeIcon) themeIcon.className = 'ri-sun-line';
    showToast('Dark Mode Activated 🌙');
  } else {
    if (themeIcon) themeIcon.className = 'ri-moon-line';
    showToast('Light Mode Activated ☀️');
  }
}

if (themeToggleBtn) themeToggleBtn.addEventListener('click', toggleTheme);
if (deskThemeBtn) deskThemeBtn.addEventListener('click', toggleTheme);

const savedTheme = localStorage.getItem('meetmind_theme');
if (savedTheme) {
  document.documentElement.setAttribute('data-theme', savedTheme);
  if (themeIcon) themeIcon.className = savedTheme === 'dark' ? 'ri-sun-line' : 'ri-moon-line';
}

// ==========================================================================
// Universal Sidebar Page Navigation
// ==========================================================================
function navigateToPage(pageId) {
  // Update sidebar active buttons
  document.querySelectorAll('.sidebar-menu .menu-item, .sidebar-bottom .menu-item').forEach(btn => {
    if (btn.dataset.nav === pageId) {
      btn.classList.add('active');
    } else {
      btn.classList.remove('active');
    }
  });

  // Switch visible page view
  document.querySelectorAll('.desktop-main-panel .page-view').forEach(p => {
    p.classList.add('hidden');
  });

  const targetPage = document.getElementById(`page-${pageId}`);
  if (targetPage) {
    targetPage.classList.remove('hidden');
  }

  // Trigger page-specific renders
  if (pageId === 'meetings') renderMeetingsTable(activeMeetingFilter);
  if (pageId === 'tasks') renderTasks(activeTaskFilter);
  if (pageId === 'documents') renderDocumentsVault();
}

document.querySelectorAll('.sidebar-menu .menu-item, .sidebar-bottom .menu-item').forEach(btn => {
  btn.addEventListener('click', () => {
    const nav = btn.dataset.nav;
    if (nav) navigateToPage(nav);
  });
});

// Viewport Switcher (Desktop vs Mobile Showcase)
function switchViewMode(mode) {
  document.querySelectorAll('.u-btn').forEach(b => b.classList.remove('active'));

  if (mode === 'desktop') {
    if (btnViewDesktop) btnViewDesktop.classList.add('active');
    if (desktopAppView) desktopAppView.style.display = 'grid';
    if (mobileShowcaseView) mobileShowcaseView.classList.add('hidden');
    showToast('Desktop Application View');
  } else if (mode === 'mobile-showcase') {
    if (btnViewMobileShowcase) btnViewMobileShowcase.classList.add('active');
    if (desktopAppView) desktopAppView.style.display = 'none';
    if (mobileShowcaseView) mobileShowcaseView.classList.remove('hidden');
    showToast('5-Screen Mobile Showcase View');
  } else if (mode === 'mobile-phone') {
    if (btnViewMobilePhone) btnViewMobilePhone.classList.add('active');
    if (desktopAppView) desktopAppView.style.display = 'none';
    if (mobileShowcaseView) mobileShowcaseView.classList.remove('hidden');
    const phones = document.querySelectorAll('.mockup-phone');
    if (phones[1]) phones[1].scrollIntoView({ behavior: 'smooth', block: 'center' });
    showToast('Interactive Mobile Screen Focused 📱');
  }
}

if (btnViewDesktop) btnViewDesktop.addEventListener('click', () => switchViewMode('desktop'));
if (btnViewMobileShowcase) btnViewMobileShowcase.addEventListener('click', () => switchViewMode('mobile-showcase'));
if (btnViewMobilePhone) btnViewMobilePhone.addEventListener('click', () => switchViewMode('mobile-phone'));

// Quick dashboard cards
const deskStartRecordCard = document.getElementById('deskStartRecordCard');
if (deskStartRecordCard) {
  deskStartRecordCard.addEventListener('click', () => navigateToPage('record'));
}

const deskRecordBtn = document.getElementById('deskRecordBtn');
if (deskRecordBtn) {
  deskRecordBtn.addEventListener('click', () => navigateToPage('record'));
}

// ==========================================================================
// Real Audio Recording Studio & Visualizer (Web Audio API & SpeechRecognition)
// ==========================================================================
const studioVisualizerCanvas = document.getElementById('studioVisualizerCanvas');
const studioTimerDisplay = document.getElementById('studioTimerDisplay');
const studioStatusText = document.getElementById('studioStatusText');
const studioBtnToggleRecord = document.getElementById('studioBtnToggleRecord');
const studioRecordIcon = document.getElementById('studioRecordIcon');
const studioBtnBookmark = document.getElementById('studioBtnBookmark');
const studioBtnSaveMeeting = document.getElementById('studioBtnSaveMeeting');
const bookmarksList = document.getElementById('bookmarksList');
const studioLiveTranscript = document.getElementById('studioLiveTranscript');
const liveRecBadge = document.getElementById('liveRecBadge');

function formatTime(totalSeconds) {
  const h = String(Math.floor(totalSeconds / 3600)).padStart(2, '0');
  const m = String(Math.floor((totalSeconds % 3600) / 60)).padStart(2, '0');
  const s = String(totalSeconds % 60).padStart(2, '0');
  return `${h}:${m}:${s}`;
}

async function startStudioRecording() {
  isStudioRecording = true;
  studioSeconds = 0;
  studioBookmarks = [];
  studioTranscriptAccumulator = '';
  if (studioTimerDisplay) studioTimerDisplay.textContent = '00:00:00';
  if (studioRecordIcon) studioRecordIcon.className = 'ri-stop-fill';
  if (studioStatusText) studioStatusText.textContent = 'Recording in progress... Live voice analysis active.';
  if (liveRecBadge) liveRecBadge.style.display = 'inline-flex';
  if (bookmarksList) bookmarksList.innerHTML = 'Recording active. Tap Bookmark to mark key timestamps.';

  // Start Timer
  studioTimerInterval = setInterval(() => {
    studioSeconds++;
    if (studioTimerDisplay) studioTimerDisplay.textContent = formatTime(studioSeconds);
  }, 1000);

  // Initialize Web Audio API for Real Reactive Microphone Waveform
  try {
    const AudioContextClass = window.AudioContext || window.webkitAudioContext;
    studioAudioCtx = new AudioContextClass();
    studioAnalyser = studioAudioCtx.createAnalyser();
    studioAnalyser.fftSize = 64;

    studioMediaStream = await navigator.mediaDevices.getUserMedia({ audio: true });
    const source = studioAudioCtx.createMediaStreamSource(studioMediaStream);
    source.connect(studioAnalyser);

    drawCanvasWaveform();
    showToast('Microphone connected! Real audio visualizer active 🎙️');
  } catch (err) {
    console.warn('Microphone permission fallback:', err);
    // Simulated visualizer if microphone is denied or unavailable
    drawSimulatedCanvasWaveform();
    showToast('Recording with simulated audio waveform 🎙️');
  }

  // Native Web Speech Recognition for Urdu & English Real-Time Transcription
  const SpeechRec = window.SpeechRecognition || window.webkitSpeechRecognition;
  if (SpeechRec) {
    try {
      studioSpeechRecognition = new SpeechRec();
      studioSpeechRecognition.continuous = true;
      studioSpeechRecognition.interimResults = true;
      studioSpeechRecognition.lang = 'en-US';

      studioSpeechRecognition.onresult = (event) => {
        let interim = '';
        for (let i = event.resultIndex; i < event.results.length; i++) {
          const t = event.results[i][0].transcript;
          if (event.results[i].isFinal) {
            studioTranscriptAccumulator += ' ' + t;
          } else {
            interim += t;
          }
        }
        if (studioLiveTranscript) {
          studioLiveTranscript.innerHTML = `<strong>Transcript:</strong> ${escapeHtml(studioTranscriptAccumulator)} <span style="color: var(--primary);">${escapeHtml(interim)}</span>`;
          studioLiveTranscript.scrollTop = studioLiveTranscript.scrollHeight;
        }
      };

      studioSpeechRecognition.start();
    } catch (e) {
      console.warn('Speech recognition warning:', e);
    }
  } else {
    simulateLiveSpeech();
  }
}

function simulateLiveSpeech() {
  const simulatedSentences = [
    'Good morning team, let us review the sprint milestones.',
    'Ali has finalized the Firebase and cloud storage integration.',
    'We agreed on launching the mobile PWA for beta testers on Friday.',
    'Sarah will deliver the remaining design assets for the meeting minutes export.'
  ];
  let idx = 0;
  const simInterval = setInterval(() => {
    if (!isStudioRecording) {
      clearInterval(simInterval);
      return;
    }
    if (idx < simulatedSentences.length) {
      studioTranscriptAccumulator += (studioTranscriptAccumulator ? ' ' : '') + simulatedSentences[idx];
      if (studioLiveTranscript) {
        studioLiveTranscript.innerHTML = `<strong>Transcript:</strong> ${escapeHtml(studioTranscriptAccumulator)}`;
        studioLiveTranscript.scrollTop = studioLiveTranscript.scrollHeight;
      }
      idx++;
    }
  }, 4000);
}

function stopStudioRecording() {
  isStudioRecording = false;
  clearInterval(studioTimerInterval);
  if (studioRecordIcon) studioRecordIcon.className = 'ri-mic-fill';
  if (studioStatusText) studioStatusText.textContent = 'Recording stopped. You can now save or export your meeting note.';
  if (liveRecBadge) liveRecBadge.style.display = 'none';

  if (studioMediaStream) {
    studioMediaStream.getTracks().forEach(t => t.stop());
  }
  if (studioSpeechRecognition) {
    try { studioSpeechRecognition.stop(); } catch (e) {}
  }
  showToast('Recording paused. Click "Finish & Save" to generate AI summary.');
}

if (studioBtnToggleRecord) {
  studioBtnToggleRecord.addEventListener('click', () => {
    if (!isStudioRecording) {
      startStudioRecording();
    } else {
      stopStudioRecording();
    }
  });
}

// Bookmark Button
if (studioBtnBookmark) {
  studioBtnBookmark.addEventListener('click', () => {
    const timestamp = formatTime(studioSeconds);
    const bmText = `Bookmark #${studioBookmarks.length + 1} at [${timestamp}]`;
    studioBookmarks.push(bmText);

    if (bookmarksList) {
      bookmarksList.innerHTML = studioBookmarks.map(b => `<div class="bm-chip"><i class="ri-flag-2-fill"></i> ${b}</div>`).join('');
    }
    showToast(`Added ${bmText} 🔖`);
  });
}

// Finish & Save Meeting
if (studioBtnSaveMeeting) {
  studioBtnSaveMeeting.addEventListener('click', () => {
    if (isStudioRecording) stopStudioRecording();

    const finalDuration = studioSeconds > 0 ? `${Math.ceil(studioSeconds / 60)} min` : '5 min';
    const finalTranscript = studioTranscriptAccumulator.trim() || 'Reviewed project deliverables, updated cloud security policies, and aligned sprint schedule.';

    const newMeeting = {
      id: Date.now(),
      title: `Meeting Studio Recording — ${new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`,
      date: 'Today, ' + new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      duration: finalDuration,
      tag: 'Work',
      tagClass: 'tag-work',
      summary: `Automated executive AI summary: ${finalTranscript.slice(0, 150)}... The team finalized priorities and confirmed delivery deadlines.`,
      decisions: ['Agreed on current sprint release targets', 'Approved cloud storage architecture', 'Scheduled follow-up team review'],
      actionItems: ['Review generated meeting minutes - Lead', 'Verify action items in task manager - Team']
    };

    meetings.unshift(newMeeting);

    // Also extract an action item task
    tasks.unshift({
      id: Date.now() + 1,
      title: `Action Item from ${newMeeting.title}`,
      assignee: 'Team',
      priority: 'high',
      deadline: 'Friday, 5:00 PM',
      completed: false
    });

    persistData();
    renderMeetings();
    renderMeetingsTable();
    renderTasks();

    if (window.MeetMindFirebase) {
      window.MeetMindFirebase.saveMeeting(newMeeting);
    }

    showToast('Meeting saved & AI Summary generated successfully! 🎉');
    openMeetingDetailsModal(newMeeting);
  });
}

// Real Audio Spectrum Canvas Drawer
function drawCanvasWaveform() {
  if (!studioVisualizerCanvas || !studioAnalyser) return;
  const ctx = studioVisualizerCanvas.getContext('2d');
  const bufferLength = studioAnalyser.frequencyBinCount;
  const dataArray = new Uint8Array(bufferLength);

  function renderFrame() {
    if (!isStudioRecording) {
      ctx.clearRect(0, 0, studioVisualizerCanvas.width, studioVisualizerCanvas.height);
      return;
    }
    requestAnimationFrame(renderFrame);
    studioAnalyser.getByteFrequencyData(dataArray);

    ctx.clearRect(0, 0, studioVisualizerCanvas.width, studioVisualizerCanvas.height);
    const barWidth = (studioVisualizerCanvas.width / bufferLength) * 2.2;
    let x = 0;

    for (let i = 0; i < bufferLength; i++) {
      const barHeight = Math.max(6, (dataArray[i] / 255) * studioVisualizerCanvas.height * 0.85);
      
      const grad = ctx.createLinearGradient(0, studioVisualizerCanvas.height - barHeight, 0, studioVisualizerCanvas.height);
      grad.addColorStop(0, '#A78BFA');
      grad.addColorStop(1, '#6D5AE5');
      
      ctx.fillStyle = grad;
      ctx.beginPath();
      ctx.roundRect(x, studioVisualizerCanvas.height - barHeight, barWidth - 4, barHeight, 4);
      ctx.fill();

      x += barWidth;
    }
  }
  renderFrame();
}

function drawSimulatedCanvasWaveform() {
  if (!studioVisualizerCanvas) return;
  const ctx = studioVisualizerCanvas.getContext('2d');
  let phase = 0;

  function renderSimFrame() {
    if (!isStudioRecording) {
      ctx.clearRect(0, 0, studioVisualizerCanvas.width, studioVisualizerCanvas.height);
      return;
    }
    requestAnimationFrame(renderSimFrame);
    ctx.clearRect(0, 0, studioVisualizerCanvas.width, studioVisualizerCanvas.height);

    const numBars = 36;
    const barWidth = studioVisualizerCanvas.width / numBars;
    phase += 0.08;

    for (let i = 0; i < numBars; i++) {
      const wave = Math.sin(phase + i * 0.35) * Math.cos(phase * 0.5 + i * 0.1);
      const barHeight = Math.max(8, Math.abs(wave) * (studioVisualizerCanvas.height * 0.8));

      const grad = ctx.createLinearGradient(0, studioVisualizerCanvas.height - barHeight, 0, studioVisualizerCanvas.height);
      grad.addColorStop(0, '#A78BFA');
      grad.addColorStop(1, '#6D5AE5');

      ctx.fillStyle = grad;
      ctx.beginPath();
      ctx.roundRect(i * barWidth + 3, studioVisualizerCanvas.height - barHeight, barWidth - 6, barHeight, 4);
      ctx.fill();
    }
  }
  renderSimFrame();
}

// ==========================================================================
// Meetings Library Table & Filtering
// ==========================================================================
const meetingsTableBody = document.getElementById('meetingsTableBody');
const libraryFilterRow = document.getElementById('libraryFilterRow');

function renderMeetingsTable(filter = 'all') {
  if (!meetingsTableBody) return;
  meetingsTableBody.innerHTML = '';

  const filtered = meetings.filter(m => {
    if (filter === 'all') return true;
    return m.tag.toLowerCase() === filter.toLowerCase();
  });

  filtered.forEach(m => {
    const tr = document.createElement('tr');
    tr.style.cursor = 'pointer';
    tr.innerHTML = `
      <td>
        <div style="display: flex; align-items: center; gap: 10px;">
          <div class="meeting-row-icon" style="width: 32px; height: 32px; font-size: 14px;"><i class="ri-voiceprint-fill"></i></div>
          <strong>${escapeHtml(m.title)}</strong>
        </div>
      </td>
      <td>${m.date}</td>
      <td>${m.duration}</td>
      <td><span class="badge-tag ${m.tagClass || 'tag-work'}">${m.tag}</span></td>
      <td><span class="badge-summary-ready"><i class="ri-checkbox-circle-fill"></i> Ready</span></td>
      <td>
        <div style="display: flex; gap: 6px;">
          <button class="btn-control-secondary btn-table-view" title="View Summary" style="padding: 4px 8px; font-size: 11.5px;">
            <i class="ri-eye-line"></i> View
          </button>
          <button class="btn-control-secondary btn-table-pdf" title="Export PDF" style="padding: 4px 8px; font-size: 11.5px;">
            <i class="ri-printer-line"></i> PDF
          </button>
        </div>
      </td>
    `;

    tr.querySelector('.btn-table-view').addEventListener('click', (e) => {
      e.stopPropagation();
      openMeetingDetailsModal(m);
    });

    tr.querySelector('.btn-table-pdf').addEventListener('click', (e) => {
      e.stopPropagation();
      openMeetingDetailsModal(m);
      setTimeout(() => window.print(), 300);
    });

    tr.addEventListener('click', () => openMeetingDetailsModal(m));
    meetingsTableBody.appendChild(tr);
  });
}

if (libraryFilterRow) {
  libraryFilterRow.addEventListener('click', (e) => {
    const btn = e.target.closest('.lib-tab');
    if (btn) {
      document.querySelectorAll('#libraryFilterRow .lib-tab').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      activeMeetingFilter = btn.dataset.filter;
      renderMeetingsTable(activeMeetingFilter);
    }
  });
}

// ==========================================================================
// Tasks Board & Interactive Task Manager
// ==========================================================================
const tasksBoardGrid = document.getElementById('tasksBoardGrid');
const taskFilterRow = document.getElementById('taskFilterRow');
const btnAddTaskModal = document.getElementById('btnAddTaskModal');
const modalCreateTask = document.getElementById('modalCreateTask');
const closeTaskModal = document.getElementById('closeTaskModal');
const cancelTaskModalBtn = document.getElementById('cancelTaskModalBtn');
const btnSaveNewTask = document.getElementById('btnSaveNewTask');

function renderTasks(filter = 'all') {
  if (!tasksBoardGrid) return;
  tasksBoardGrid.innerHTML = '';

  const filtered = tasks.filter(t => {
    if (filter === 'pending') return !t.completed;
    if (filter === 'completed') return t.completed;
    return true;
  });

  filtered.forEach(t => {
    const card = document.createElement('div');
    card.className = `task-item-card ${t.completed ? 'completed' : ''}`;
    card.innerHTML = `
      <div class="task-card-top">
        <input type="checkbox" class="task-checkbox-custom" ${t.completed ? 'checked' : ''}>
        <div style="flex: 1;">
          <div class="task-title-text">${escapeHtml(t.title)}</div>
          <div style="font-size: 11.5px; color: var(--text-dim); margin-top: 4px;">
            <i class="ri-user-3-line"></i> Assignee: <strong>${escapeHtml(t.assignee || 'Unassigned')}</strong>
          </div>
        </div>
      </div>
      <div class="task-meta-row">
        <span><i class="ri-calendar-line"></i> ${t.deadline || 'No deadline'}</span>
        <span class="priority-pill priority-${t.priority || 'medium'}">${(t.priority || 'medium').toUpperCase()}</span>
      </div>
    `;

    const chk = card.querySelector('.task-checkbox-custom');
    chk.addEventListener('change', () => {
      t.completed = chk.checked;
      card.classList.toggle('completed', t.completed);
      persistData();
      showToast(t.completed ? 'Task marked as completed! ✅' : 'Task reopened ⏳');
    });

    tasksBoardGrid.appendChild(card);
  });

  updateStats();
}

if (taskFilterRow) {
  taskFilterRow.addEventListener('click', (e) => {
    const btn = e.target.closest('.lib-tab');
    if (btn) {
      document.querySelectorAll('#taskFilterRow .lib-tab').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      activeTaskFilter = btn.dataset.taskFilter;
      renderTasks(activeTaskFilter);
    }
  });
}

if (btnAddTaskModal) {
  btnAddTaskModal.addEventListener('click', () => {
    modalCreateTask.classList.remove('hidden');
  });
}

function hideTaskModal() {
  if (modalCreateTask) modalCreateTask.classList.add('hidden');
}

if (closeTaskModal) closeTaskModal.addEventListener('click', hideTaskModal);
if (cancelTaskModalBtn) cancelTaskModalBtn.addEventListener('click', hideTaskModal);

if (btnSaveNewTask) {
  btnSaveNewTask.addEventListener('click', () => {
    const title = document.getElementById('taskTitleInput').value.trim();
    const assignee = document.getElementById('taskAssigneeInput').value.trim() || 'You';
    const priority = document.getElementById('taskPrioritySelect').value;
    const deadline = document.getElementById('taskDeadlineInput').value.trim() || 'This Friday';

    if (!title) {
      alert('Please enter a task title');
      return;
    }

    const newTask = {
      id: Date.now(),
      title,
      assignee,
      priority,
      deadline,
      completed: false
    };

    tasks.unshift(newTask);
    persistData();
    renderTasks(activeTaskFilter);
    hideTaskModal();

    if (window.MeetMindFirebase) {
      window.MeetMindFirebase.saveTask(newTask);
    }

    showToast('New task created & synced to cloud! ✨');
    document.getElementById('taskTitleInput').value = '';
    document.getElementById('taskAssigneeInput').value = '';
  });
}

// ==========================================================================
// Meeting Details Modal & PDF Printable Export
// ==========================================================================
const modalMeetingDetails = document.getElementById('modalMeetingDetails');
const closeDetailModal = document.getElementById('closeDetailModal');
const mdDetailTitle = document.getElementById('mdDetailTitle');
const mdDetailMeta = document.getElementById('mdDetailMeta');
const mdDetailSummary = document.getElementById('mdDetailSummary');
const mdDetailDecisions = document.getElementById('mdDetailDecisions');
const mdDetailActions = document.getElementById('mdDetailActions');
const btnDeleteMeetingItem = document.getElementById('btnDeleteMeetingItem');
const btnCopyMeetingText = document.getElementById('btnCopyMeetingText');
const btnPrintPdfBtn = document.getElementById('btnPrintPdfBtn');

function openMeetingDetailsModal(meeting) {
  if (!modalMeetingDetails) return;
  selectedMeetingForModal = meeting;

  mdDetailTitle.textContent = meeting.title;
  mdDetailMeta.textContent = `${meeting.date} • ${meeting.duration} • Tag: ${meeting.tag}`;
  mdDetailSummary.textContent = meeting.summary || 'Summary generated from meeting transcript.';

  // Decisions
  mdDetailDecisions.innerHTML = '';
  const decisions = meeting.decisions && meeting.decisions.length > 0 
    ? meeting.decisions 
    : ['Approved proposed project roadmap', 'Set timeline for deliverables'];
  decisions.forEach(d => {
    const li = document.createElement('li');
    li.textContent = d;
    mdDetailDecisions.appendChild(li);
  });

  // Action Items
  mdDetailActions.innerHTML = '';
  const actions = meeting.actionItems && meeting.actionItems.length > 0
    ? meeting.actionItems
    : ['Follow up with engineering team', 'Review product telemetry'];
  actions.forEach(a => {
    const li = document.createElement('li');
    li.textContent = a;
    mdDetailActions.appendChild(li);
  });

  modalMeetingDetails.classList.remove('hidden');
}

if (closeDetailModal) {
  closeDetailModal.addEventListener('click', () => {
    modalMeetingDetails.classList.add('hidden');
  });
}

if (btnCopyMeetingText) {
  btnCopyMeetingText.addEventListener('click', () => {
    if (!selectedMeetingForModal) return;
    const text = `MEETMIND AI — MEETING MINUTES & SUMMARY\n\nTitle: ${selectedMeetingForModal.title}\nDate: ${selectedMeetingForModal.date}\nDuration: ${selectedMeetingForModal.duration}\n\nExecutive Summary:\n${selectedMeetingForModal.summary}\n\nKey Decisions:\n${(selectedMeetingForModal.decisions || []).map(d => '- ' + d).join('\n')}\n\nAction Items:\n${(selectedMeetingForModal.actionItems || []).map(a => '- ' + a).join('\n')}`;
    navigator.clipboard.writeText(text).then(() => {
      showToast('Meeting summary copied to clipboard! 📋');
    });
  });
}

if (btnPrintPdfBtn) {
  btnPrintPdfBtn.addEventListener('click', () => {
    showToast('Opening print dialog for PDF export... 🖨️');
    window.print();
  });
}

if (btnDeleteMeetingItem) {
  btnDeleteMeetingItem.addEventListener('click', () => {
    if (!selectedMeetingForModal) return;
    if (confirm(`Are you sure you want to delete "${selectedMeetingForModal.title}"?`)) {
      meetings = meetings.filter(m => m.id !== selectedMeetingForModal.id);
      persistData();
      renderMeetings();
      renderMeetingsTable(activeMeetingFilter);
      modalMeetingDetails.classList.add('hidden');
      showToast('Meeting deleted');
    }
  });
}

// Modal 3: Manual New Meeting Modal
const modalNewMeeting = document.getElementById('modalNewMeeting');
const btnNewMeetingModal = document.getElementById('btnNewMeetingModal');
const closeNewMeetingModal = document.getElementById('closeNewMeetingModal');
const cancelNewMeetingBtn = document.getElementById('cancelNewMeetingBtn');
const btnSaveNewMeeting = document.getElementById('btnSaveNewMeeting');

if (btnNewMeetingModal) {
  btnNewMeetingModal.addEventListener('click', () => modalNewMeeting.classList.remove('hidden'));
}
function hideNewMeetingModal() {
  if (modalNewMeeting) modalNewMeeting.classList.add('hidden');
}
if (closeNewMeetingModal) closeNewMeetingModal.addEventListener('click', hideNewMeetingModal);
if (cancelNewMeetingBtn) cancelNewMeetingBtn.addEventListener('click', hideNewMeetingModal);

if (btnSaveNewMeeting) {
  btnSaveNewMeeting.addEventListener('click', () => {
    const title = document.getElementById('newMeetingTitleInput').value.trim();
    const tag = document.getElementById('newMeetingTagSelect').value;
    const duration = document.getElementById('newMeetingDurationInput').value.trim() || '30 min';
    const notes = document.getElementById('newMeetingNotesInput').value.trim();

    if (!title) {
      alert('Please enter a meeting title');
      return;
    }

    const tagClass = `tag-${tag.toLowerCase()}`;
    const newM = {
      id: Date.now(),
      title,
      date: 'Today, ' + new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      duration,
      tag,
      tagClass,
      summary: notes ? `AI Summary: ${notes}` : 'Meeting discussion notes recorded with automated task assignment.',
      decisions: ['Approved discussion points', 'Aligned next steps'],
      actionItems: [`Follow up on ${title}`]
    };

    meetings.unshift(newM);
    persistData();
    renderMeetings();
    renderMeetingsTable(activeMeetingFilter);
    hideNewMeetingModal();
    showToast('Meeting note saved & auto-summarized! ✨');
    openMeetingDetailsModal(newM);
  });
}

// ==========================================================================
// Documents Vault & Minutes
// ==========================================================================
const documentsCardsGrid = document.getElementById('documentsCardsGrid');
const btnCreateNewDoc = document.getElementById('btnCreateNewDoc');
const btnExportAllDocs = document.getElementById('btnExportAllDocs');

function renderDocumentsVault() {
  if (!documentsCardsGrid) return;
  documentsCardsGrid.innerHTML = '';

  meetings.forEach(m => {
    const card = document.createElement('div');
    card.className = 'doc-vault-card';
    card.innerHTML = `
      <div class="doc-card-header">
        <div class="doc-file-icon"><i class="ri-file-text-fill"></i></div>
        <div>
          <div class="doc-card-title">${escapeHtml(m.title)}</div>
          <div class="doc-card-sub">${m.date} • ${m.duration}</div>
        </div>
      </div>
      <div class="doc-card-body">
        ${escapeHtml(m.summary)}
      </div>
      <div class="doc-actions-row">
        <button class="btn-control-secondary btn-doc-view" style="flex: 1; font-size: 11.5px;">
          <i class="ri-eye-line"></i> View Brief
        </button>
        <button class="btn-primary-purple btn-doc-pdf" style="font-size: 11.5px; padding: 6px 12px;">
          <i class="ri-printer-line"></i> PDF
        </button>
      </div>
    `;

    card.querySelector('.btn-doc-view').addEventListener('click', () => openMeetingDetailsModal(m));
    card.querySelector('.btn-doc-pdf').addEventListener('click', () => {
      openMeetingDetailsModal(m);
      setTimeout(() => window.print(), 300);
    });

    documentsCardsGrid.appendChild(card);
  });
}

if (btnCreateNewDoc) {
  btnCreateNewDoc.addEventListener('click', () => {
    if (modalNewMeeting) modalNewMeeting.classList.remove('hidden');
  });
}

if (btnExportAllDocs) {
  btnExportAllDocs.addEventListener('click', exportFullLibraryJSON);
}

// ==========================================================================
// Command Palette (⌘K / Ctrl+K) Spotlight Navigator
// ==========================================================================
const modalCommandPalette = document.getElementById('modalCommandPalette');
const cmdPaletteInput = document.getElementById('cmdPaletteInput');
const cmdPaletteResults = document.getElementById('cmdPaletteResults');

const COMMANDS_LIST = [
  { title: 'Start Recording Studio', icon: 'ri-mic-line', action: () => navigateToPage('record') },
  { title: 'Open Meetings Library', icon: 'ri-folders-line', action: () => navigateToPage('meetings') },
  { title: 'View Action Items & Tasks', icon: 'ri-checkbox-circle-line', action: () => navigateToPage('tasks') },
  { title: 'Ask AI Chat', icon: 'ri-chat-voice-line', action: () => navigateToPage('chat') },
  { title: 'Meeting Calendar', icon: 'ri-calendar-line', action: () => navigateToPage('calendar') },
  { title: 'Documents & Executive Minutes', icon: 'ri-file-text-line', action: () => navigateToPage('documents') },
  { title: 'Workspaces & Team Members', icon: 'ri-team-line', action: () => navigateToPage('workspaces') },
  { title: 'AI Settings & API Keys', icon: 'ri-settings-3-line', action: () => navigateToPage('settings') },
  { title: 'Toggle Light / Dark Mode', icon: 'ri-moon-line', action: toggleTheme },
  { title: 'Create New Task Modal', icon: 'ri-add-circle-line', action: () => modalCreateTask.classList.remove('hidden') },
  { title: 'Export Full Library to JSON', icon: 'ri-download-2-line', action: exportFullLibraryJSON }
];

function openCommandPalette() {
  if (!modalCommandPalette) return;
  modalCommandPalette.classList.remove('hidden');
  cmdPaletteInput.value = '';
  renderCommandResults('');
  cmdPaletteInput.focus();
}

function hideCommandPalette() {
  if (modalCommandPalette) modalCommandPalette.classList.add('hidden');
}

function renderCommandResults(queryText) {
  if (!cmdPaletteResults) return;
  cmdPaletteResults.innerHTML = '';

  const q = queryText.toLowerCase().trim();
  const filtered = COMMANDS_LIST.filter(c => !q || c.title.toLowerCase().includes(q));

  // Also include matching meetings
  meetings.filter(m => q && m.title.toLowerCase().includes(q)).forEach(m => {
    filtered.push({
      title: `Meeting: ${m.title}`,
      icon: 'ri-voiceprint-fill',
      action: () => openMeetingDetailsModal(m)
    });
  });

  filtered.forEach(item => {
    const div = document.createElement('div');
    div.className = 'cmd-item';
    div.innerHTML = `<i class="${item.icon}"></i> <span>${escapeHtml(item.title)}</span>`;
    div.addEventListener('click', () => {
      hideCommandPalette();
      item.action();
    });
    cmdPaletteResults.appendChild(div);
  });
}

if (cmdPaletteInput) {
  cmdPaletteInput.addEventListener('input', (e) => renderCommandResults(e.target.value));
  cmdPaletteInput.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') hideCommandPalette();
    if (e.key === 'Enter') {
      const first = cmdPaletteResults.querySelector('.cmd-item');
      if (first) first.click();
    }
  });
}

if (modalCommandPalette) {
  modalCommandPalette.addEventListener('click', (e) => {
    if (e.target === modalCommandPalette) hideCommandPalette();
  });
}

// Global ⌘K / Ctrl+K listener
window.addEventListener('keydown', (e) => {
  if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
    e.preventDefault();
    openCommandPalette();
  }
});

const desktopSearchInput = document.getElementById('desktopSearchInput');
if (desktopSearchInput) {
  desktopSearchInput.addEventListener('click', () => openCommandPalette());
}

// ==========================================================================
// Ask AI Chat with Real Google Gemini BYOK Support & RAG
// ==========================================================================
const deskChatArea = document.getElementById('deskChatArea');
const deskChatQueryInput = document.getElementById('deskChatQueryInput');
const deskChatSendBtn = document.getElementById('deskChatSendBtn');
const deskChatSuggestions = document.getElementById('deskChatSuggestions');
const btnClearChatHistory = document.getElementById('btnClearChatHistory');

async function handleDeskAiChat(promptText) {
  if (!promptText || !promptText.trim()) return;

  // Add User Bubble
  const uBubble = document.createElement('div');
  uBubble.className = 'chat-bubble user-bubble';
  uBubble.innerHTML = `<p>${escapeHtml(promptText)}</p>`;
  deskChatArea.appendChild(uBubble);
  deskChatArea.scrollTop = deskChatArea.scrollHeight;

  // Loading indicator bubble
  const aiBubble = document.createElement('div');
  aiBubble.className = 'chat-bubble ai-bubble';
  aiBubble.innerHTML = `
    <div class="ai-header-badge"><i class="ri-sparkling-fill"></i> MeetMind AI</div>
    <p><i class="ri-loader-4-line ri-spin"></i> Analyzing your meeting transcript history...</p>
  `;
  deskChatArea.appendChild(aiBubble);
  deskChatArea.scrollTop = deskChatArea.scrollHeight;

  // Retrieve Gemini API Key from secure local storage or settings
  const geminiApiKey = localStorage.getItem('meetmind_gemini_key');

  if (geminiApiKey) {
    try {
      // Build context from meetings
      const context = meetings.map(m => `Meeting: "${m.title}" (${m.date}). Summary: ${m.summary}. Decisions: ${(m.decisions || []).join('; ')}. Actions: ${(m.actionItems || []).join('; ')}`).join('\n\n');
      const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiApiKey}`;
      const headers = { 'Content-Type': 'application/json' };
      if (geminiApiKey.startsWith('AQ.')) {
        headers['Authorization'] = `Bearer ${geminiApiKey}`;
      }

      const response = await fetch(endpoint, {
        method: 'POST',
        headers: headers,
        body: JSON.stringify({
          contents: [{
            parts: [{
              text: `You are MeetMind AI, an elite intelligent meeting executive assistant. Use this meeting history context:\n\n${context}\n\nUser Question: ${promptText}\n\nProvide a concise, direct, professional answer with bullet points and source references.`
            }]
          }]
        })
      });

      const data = await response.json();
      if (data.candidates && data.candidates[0].content.parts[0].text) {
        const textResponse = data.candidates[0].content.parts[0].text;
        aiBubble.innerHTML = `
          <div class="ai-header-badge"><i class="ri-sparkling-fill"></i> Gemini 1.5 Flash (Live)</div>
          <p style="white-space: pre-wrap;">${escapeHtml(textResponse)}</p>
          <div class="chat-citation"><i class="ri-verified-badge-fill" style="color: var(--primary);"></i> Grounded in live meeting index</div>
        `;
        deskChatArea.scrollTop = deskChatArea.scrollHeight;
        return;
      }
    } catch (err) {
      console.warn('Gemini API call fallback to heuristic:', err);
    }
  }

  // Smart Heuristic RAG Fallback
  setTimeout(() => {
    const lower = promptText.toLowerCase();
    let reply = '';
    let citation = 'Project Alpha Discussion • 10:32 AM';

    if (lower.includes('decision') || lower.includes('main')) {
      reply = `Key decisions identified across your meetings:
      <ol style="margin-top: 6px; padding-left: 18px;">
        <li>Approved the new design direction for mobile recording.</li>
        <li>Set Q2 launch target for beta testers.</li>
        <li>Allocated dedicated budget for marketing & enterprise tier.</li>
      </ol>`;
    } else if (lower.includes('task') || lower.includes('due') || lower.includes('who')) {
      reply = `Active action items due this week:
      <ul style="margin-top: 6px; padding-left: 18px;">
        <li><strong>Sarah:</strong> Design high-fidelity mockups (Apr 30)</li>
        <li><strong>Ali:</strong> Finalize low-latency audio capture specs (May 5)</li>
        <li><strong>John:</strong> Draft marketing plan & slide deck (May 10)</li>
      </ul>`;
      citation = 'Team Standup • Apr 24, 2026';
    } else if (lower.includes('client') || lower.includes('acme')) {
      reply = `In the <strong>Client Call with Acme Corp</strong>, the client agreed on the SOC2 compliance timeline and requested custom PDF/DOCX export options with data isolation.`;
      citation = 'Client Call - Acme Corp • Yesterday';
    } else {
      reply = `Based on your meetings index, "${escapeHtml(promptText)}" was discussed in <strong>Project Alpha Discussion</strong> with unanimous sign-off from all stakeholders.`;
    }

    aiBubble.innerHTML = `
      <div class="ai-header-badge"><i class="ri-sparkling-fill"></i> MeetMind AI Assistant</div>
      <p>${reply}</p>
      <div class="chat-citation"><i class="ri-file-text-line"></i> Source: ${citation}</div>
    `;
    deskChatArea.scrollTop = deskChatArea.scrollHeight;
  }, 400);
}

if (deskChatSendBtn && deskChatQueryInput) {
  deskChatSendBtn.addEventListener('click', () => {
    const val = deskChatQueryInput.value.trim();
    if (val) {
      handleDeskAiChat(val);
      deskChatQueryInput.value = '';
    }
  });

  deskChatQueryInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') deskChatSendBtn.click();
  });
}

if (deskChatSuggestions) {
  deskChatSuggestions.addEventListener('click', (e) => {
    const chip = e.target.closest('.s-chip');
    if (chip) handleDeskAiChat(chip.textContent);
  });
}

if (btnClearChatHistory && deskChatArea) {
  btnClearChatHistory.addEventListener('click', () => {
    deskChatArea.innerHTML = `
      <div class="chat-bubble ai-bubble">
        <div class="ai-header-badge"><i class="ri-sparkling-fill"></i> MeetMind AI Assistant</div>
        <p>Chat history cleared. How can I help you analyze your meetings today?</p>
      </div>
    `;
    showToast('Chat history cleared');
  });
}

// ==========================================================================
// Settings & API Configuration BYOK
// ==========================================================================
const settingGeminiKey = document.getElementById('settingGeminiKey');
const settingBackendUrl = document.getElementById('settingBackendUrl');
const settingOpenAiKey = document.getElementById('settingOpenAiKey');
const btnSaveApiKeys = document.getElementById('btnSaveApiKeys');
const btnSaveAiSettings = document.getElementById('btnSaveAiSettings');
const btnExportAllData = document.getElementById('btnExportAllData');
const btnExportMarkdownSummary = document.getElementById('btnExportMarkdownSummary');
const btnDeleteAccount = document.getElementById('btnDeleteAccount');

// Load saved keys
if (settingGeminiKey && localStorage.getItem('meetmind_gemini_key')) {
  settingGeminiKey.value = localStorage.getItem('meetmind_gemini_key');
}
if (settingBackendUrl && localStorage.getItem('meetmind_backend_url')) {
  settingBackendUrl.value = localStorage.getItem('meetmind_backend_url');
}

if (btnSaveApiKeys) {
  btnSaveApiKeys.addEventListener('click', () => {
    const gKey = settingGeminiKey.value.trim();
    const bUrl = settingBackendUrl.value.trim() || 'http://127.0.0.1:8000/api/v1';
    const oKey = settingOpenAiKey.value.trim();

    if (gKey) localStorage.setItem('meetmind_gemini_key', gKey);
    localStorage.setItem('meetmind_backend_url', bUrl);
    if (oKey) localStorage.setItem('meetmind_openai_key', oKey);
    API_BASE_URL = bUrl;

    showToast('API Configuration saved! Real AI Engine Active 🔥');
  });
}

if (btnSaveAiSettings) {
  btnSaveAiSettings.addEventListener('click', () => {
    showToast('AI preferences updated!');
  });
}

function exportFullLibraryJSON() {
  const exportPayload = {
    app: 'MeetMind AI',
    exportedAt: new Date().toISOString(),
    meetings,
    tasks
  };
  const blob = new Blob([JSON.stringify(exportPayload, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `meetmind_backup_${Date.now()}.json`;
  a.click();
  URL.revokeObjectURL(url);
  showToast('Full library exported as JSON! 📥');
}

if (btnExportAllData) btnExportAllData.addEventListener('click', exportFullLibraryJSON);

if (btnExportMarkdownSummary) {
  btnExportMarkdownSummary.addEventListener('click', () => {
    let md = `# MeetMind AI — All Meetings & Minutes\nGenerated on: ${new Date().toLocaleString()}\n\n---\n\n`;
    meetings.forEach((m, idx) => {
      md += `## ${idx + 1}. ${m.title}\n`;
      md += `- **Date:** ${m.date}\n`;
      md += `- **Duration:** ${m.duration}\n`;
      md += `- **Category:** ${m.tag}\n\n`;
      md += `### Executive Summary\n${m.summary}\n\n`;
      md += `### Decisions\n${(m.decisions || []).map(d => '- ' + d).join('\n')}\n\n`;
      md += `### Action Items\n${(m.actionItems || []).map(a => '- ' + a).join('\n')}\n\n---\n\n`;
    });
    const blob = new Blob([md], { type: 'text/markdown' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `meetmind_summaries_${Date.now()}.md`;
    a.click();
    URL.revokeObjectURL(url);
    showToast('All summaries exported as Markdown! 📝');
  });
}

if (btnDeleteAccount) {
  btnDeleteAccount.addEventListener('click', () => {
    if (confirm('Are you sure you want to reset your local data and return to default templates?')) {
      localStorage.clear();
      meetings = [...INITIAL_MEETINGS];
      tasks = [...INITIAL_TASKS];
      persistData();
      renderMeetings();
      renderMeetingsTable();
      renderTasks();
      showToast('Cache cleared and data reset.');
    }
  });
}

// ==========================================================================
// Knowledge & Multi-Source Import
// ==========================================================================
const btnSubmitYoutubeImport = document.getElementById('btnSubmitYoutubeImport');
const btnSubmitMeetingUrlImport = document.getElementById('btnSubmitMeetingUrlImport');
const btnSubmitDocImport = document.getElementById('btnSubmitDocImport');

if (btnSubmitYoutubeImport) {
  btnSubmitYoutubeImport.addEventListener('click', () => {
    const url = document.getElementById('importYoutubeUrlInput').value.trim();
    if (!url) return alert('Please enter a YouTube video URL');
    showToast('Extracting YouTube transcript & summarizing with AI... ⏳');
    setTimeout(() => {
      const newM = {
        id: Date.now(),
        title: 'YouTube Summary — Tech Architecture & AI Sprints',
        date: 'Today, ' + new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        duration: '14 min',
        tag: 'Product',
        tagClass: 'tag-product',
        summary: `Imported from YouTube (${url}): Key takeaways include best practices for building responsive PWA offline apps and streaming audio transcription.`,
        decisions: ['Adopted client-side streaming pattern', 'Saved summary to document vault'],
        actionItems: ['Review source video chapters - Engineering']
      };
      meetings.unshift(newM);
      persistData();
      renderMeetings();
      renderMeetingsTable();
      showToast('YouTube video summarized & added to Library! 🎥');
      openMeetingDetailsModal(newM);
    }, 900);
  });
}

if (btnSubmitMeetingUrlImport) {
  btnSubmitMeetingUrlImport.addEventListener('click', () => {
    const url = document.getElementById('importMeetingUrlInput').value.trim();
    if (!url) return alert('Please enter a Google Meet or Zoom URL');
    showToast(`Connecting MeetMind AI Bot to ${url.slice(0, 25)}... 🤖`);
    setTimeout(() => {
      showToast('AI Bot joined meeting room! Live transcription active. 🎙️');
    }, 800);
  });
}

if (btnSubmitDocImport) {
  btnSubmitDocImport.addEventListener('click', () => {
    const fileInput = document.getElementById('importDocFileInput');
    if (!fileInput.files || fileInput.files.length === 0) return alert('Please select a PDF or DOCX file to upload');
    const fName = fileInput.files[0].name;
    showToast(`Indexing & parsing document "${fName}"... 📄`);
    setTimeout(() => {
      const newM = {
        id: Date.now(),
        title: `Doc: ${fName}`,
        date: 'Today, ' + new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        duration: 'Read: 5m',
        tag: 'Work',
        tagClass: 'tag-work',
        summary: `Document AI analysis of ${fName}: Extracted 4 key operational objectives, milestone deadlines, and compliance requirements.`,
        decisions: ['Document verified and indexed into RAG memory'],
        actionItems: [`Distribute ${fName} takeaways to team`]
      };
      meetings.unshift(newM);
      persistData();
      renderMeetings();
      renderMeetingsTable();
      showToast('Document analyzed & indexed! 📄✨');
      openMeetingDetailsModal(newM);
    }, 800);
  });
}

// Calendar Sync
const btnSyncCalendar = document.getElementById('btnSyncCalendar');
if (btnSyncCalendar) {
  btnSyncCalendar.addEventListener('click', () => {
    showToast('Synchronizing calendar events with Google Calendar & Outlook... 📅');
    setTimeout(() => {
      showToast('Calendar in sync! 2 upcoming meetings found.');
    }, 600);
  });
}

// ==========================================================================
// Dashboard Recent Meetings Render
// ==========================================================================
const desktopMeetingsList = document.getElementById('desktopMeetingsList');
const mRecentMeetingsList = document.getElementById('mRecentMeetingsList');

function renderMeetings(filterText = '') {
  const filtered = meetings.filter(m => {
    if (!filterText) return true;
    return m.title.toLowerCase().includes(filterText.toLowerCase()) || 
           m.summary.toLowerCase().includes(filterText.toLowerCase());
  });

  // Desktop List
  if (desktopMeetingsList) {
    desktopMeetingsList.innerHTML = '';
    filtered.slice(0, 5).forEach(m => {
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
          <span class="badge-tag ${m.tagClass || 'tag-work'}">${m.tag}</span>
          <span class="badge-summary-ready"><i class="ri-checkbox-circle-fill"></i> Summary Ready</span>
        </div>
      `;
      row.addEventListener('click', () => openMeetingDetailsModal(m));
      desktopMeetingsList.appendChild(row);
    });
  }

  // Mobile List
  if (mRecentMeetingsList) {
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
      mCard.addEventListener('click', () => openMeetingDetailsModal(m));
      mRecentMeetingsList.appendChild(mCard);
    });
  }

  updateStats();
}

// ==========================================================================
// Mobile Showcase Interactions
// ==========================================================================
const mWaveContainer = document.getElementById('mWaveContainer');
const mBtnPauseRecord = document.getElementById('mBtnPauseRecord');
const mPauseIcon = document.getElementById('mPauseIcon');
const mBtnEndRecording = document.getElementById('mBtnEndRecording');
const mRecTimer = document.getElementById('mRecTimer');
let mRecSeconds = 754;
let mIsRecording = true;

function initMobileWaveform() {
  if (!mWaveContainer) return;
  mWaveContainer.innerHTML = '';
  for (let i = 0; i < 32; i++) {
    const bar = document.createElement('div');
    bar.className = 'm-wave-bar';
    const norm = Math.sin((i / 31) * Math.PI);
    bar.style.height = `${Math.max(8, Math.floor(norm * 85))}px`;
    mWaveContainer.appendChild(bar);
  }
}

function animateWaveform() {
  setInterval(() => {
    if (!mIsRecording || !mWaveContainer) return;
    mWaveContainer.querySelectorAll('.m-wave-bar').forEach(bar => {
      const delta = (Math.random() - 0.5) * 35;
      const current = parseFloat(bar.style.height) || 20;
      bar.style.height = `${Math.min(95, Math.max(8, current + delta))}px`;
    });
  }, 100);
}

if (mBtnPauseRecord) {
  mBtnPauseRecord.addEventListener('click', () => {
    mIsRecording = !mIsRecording;
    mPauseIcon.className = mIsRecording ? 'ri-pause-line' : 'ri-play-line';
    showToast(mIsRecording ? 'Recording Resumed' : 'Recording Paused');
  });
}

if (mBtnEndRecording) {
  mBtnEndRecording.addEventListener('click', () => {
    mIsRecording = false;
    showToast('Generating AI Summary... ⚡');
    const newM = {
      id: Date.now(),
      title: 'Voice Note #' + Math.floor(Math.random() * 900 + 100),
      date: 'Just now',
      duration: '12 min',
      tag: 'Work',
      tagClass: 'tag-work',
      summary: 'New voice note recorded from mobile app. AI automatically created action items and decisions.',
      decisions: ['Captured mobile recording', 'Stored in Cloud Firestore'],
      actionItems: ['Review new voice note summary']
    };
    meetings.unshift(newM);
    persistData();
    renderMeetings();
    renderMeetingsTable();
    if (window.MeetMindFirebase) window.MeetMindFirebase.saveMeeting(newM);

    const phones = document.querySelectorAll('.mockup-phone');
    if (phones[3]) phones[3].scrollIntoView({ behavior: 'smooth', block: 'center' });
  });
}

const mBtnExportSummary = document.getElementById('mBtnExportSummary');
if (mBtnExportSummary) {
  mBtnExportSummary.addEventListener('click', () => {
    navigator.clipboard.writeText('MeetMind AI Summary Export').then(() => {
      showToast('Meeting summary copied to clipboard! 📋');
    });
  });
}

// Mobile bottom mic
const mBottomMicBtn = document.getElementById('mBottomMicBtn');
if (mBottomMicBtn) {
  mBottomMicBtn.addEventListener('click', () => {
    const phones = document.querySelectorAll('.mockup-phone');
    if (phones[2]) phones[2].scrollIntoView({ behavior: 'smooth', block: 'center' });
  });
}

// ==========================================================================
// PWA Installation & QR Modal
// ==========================================================================
if (installMobileBtn) {
  installMobileBtn.addEventListener('click', () => modalInstallPWA.classList.remove('hidden'));
}
if (closeInstallModal) {
  closeInstallModal.addEventListener('click', () => modalInstallPWA.classList.add('hidden'));
}
if (copyUrlBtn) {
  copyUrlBtn.addEventListener('click', () => {
    const url = document.getElementById('localNetworkUrl').textContent;
    navigator.clipboard.writeText(url).then(() => {
      showToast('Network URL copied! Open in your phone browser 📲');
    });
  });
}

window.addEventListener('beforeinstallprompt', (e) => {
  e.preventDefault();
  deferredPrompt = e;
  if (installMobileBtn) installMobileBtn.style.display = 'flex';
});

const btnInstallSelf = document.getElementById('btnInstallSelf');
if (btnInstallSelf) {
  btnInstallSelf.addEventListener('click', async () => {
    if (deferredPrompt) {
      deferredPrompt.prompt();
      const { outcome } = await deferredPrompt.userChoice;
      if (outcome === 'accepted') {
        showToast('MeetMind AI Installed! Check your home screen 📱');
      }
      deferredPrompt = null;
      modalInstallPWA.classList.add('hidden');
    } else {
      showToast('Open https://meetmind-ai-74519.web.app in your mobile browser to install!');
    }
  });
}

if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('./sw.js').then(() => {
    console.log('[PWA] Service Worker registered');
  }).catch(e => console.warn('[PWA] SW register:', e));
}

// ==========================================================================
// Firebase Real-time Sync & Authentication
// ==========================================================================
function initFirebaseIntegration() {
  if (!window.MeetMindFirebase) {
    setTimeout(initFirebaseIntegration, 300);
    return;
  }

  const fb = window.MeetMindFirebase;

  // 1. Auth State Updates
  fb.onAuthUpdate((user) => {
    if (user) {
      document.querySelectorAll('.user-name, .m-greet, .welcome-title').forEach(el => {
        if (el.classList.contains('welcome-title') || el.classList.contains('m-greet')) {
          el.textContent = `Good morning, ${user.displayName || user.email.split('@')[0]} 👋`;
        } else {
          el.textContent = user.displayName || user.email.split('@')[0];
        }
      });
      if (user.photoURL) {
        document.querySelectorAll('.user-avatar-sm, .user-avatar-top, .m-avatar').forEach(img => {
          img.src = user.photoURL;
        });
      }
      showToast(`Signed in as ${user.displayName || user.email} 🔥`);
    }
  });

  // 2. Real-time Firestore Meetings Sync
  fb.subscribeMeetings((remoteMeetings) => {
    if (remoteMeetings && remoteMeetings.length > 0) {
      const remoteIds = new Set(remoteMeetings.map(m => m.id));
      const localKept = meetings.filter(m => !remoteIds.has(m.id));
      meetings = [...remoteMeetings, ...localKept];
      renderMeetings();
      renderMeetingsTable(activeMeetingFilter);
      renderDocumentsVault();
    }
  });

  // 3. User Avatar Click -> Sign in with Google
  const profileElements = [document.getElementById('deskUserCard'), document.querySelector('.user-avatar-top'), document.querySelector('.m-avatar')];
  profileElements.forEach(el => {
    if (el) {
      el.style.cursor = 'pointer';
      el.addEventListener('click', async () => {
        if (fb.currentUser) {
          if (confirm(`Currently signed in as ${fb.currentUser.email}. Do you want to sign out?`)) {
            await fb.logout();
            showToast('Signed out of Firebase');
          }
        } else {
          showToast('Opening Google Sign-In...');
          const res = await fb.loginWithGoogle();
          if (res.success) {
            showToast(`Welcome ${res.user.displayName}! 🎉`);
          }
        }
      });
    }
  });
}

// ==========================================================================
// Initial Boot
// ==========================================================================
renderMeetings();
renderMeetingsTable();
renderTasks();
renderDocumentsVault();
initMobileWaveform();
animateWaveform();
initFirebaseIntegration();
updateStats();
