const fs = require('fs');

let code = fs.readFileSync('app.js', 'utf8');

// 1. Add DEMO_COMMERCIAL_MEETING after DEMO_SAMPLE_MEETING
const targetSampleMeeting = `  transcript: 'Welcome team. Let us review Project Alpha deliverables. We have verified cloud data isolation and low-latency audio streams. Action items are assigned and ready for sprint kickoff.'\n};`;

const demoCommercialMeeting = `  transcript: 'Welcome team. Let us review Project Alpha deliverables. We have verified cloud data isolation and low-latency audio streams. Action items are assigned and ready for sprint kickoff.'
};

const DEMO_COMMERCIAL_MEETING = {
  id: 1002,
  title: 'Client Commercials & Pakistan Gateway Sync',
  date: 'Yesterday, 3:15 PM',
  duration: '21 min',
  tag: 'General',
  tagClass: 'tag-general',
  isSample: true,
  summary: 'Reviewed client commercials and finalized localized payment gateways. Approved JazzCash, Easypaisa, and Raast instant settlement channels to resolve payment delays.',
  decisions: [
    'Approved JazzCash and Easypaisa checkout',
    'Pricing set at 3,900 PKR/mo Pro with instant activation',
    'Zero gateway surcharge on Raast'
  ],
  actionItems: [
    'Deploy checkout modal - Hasnain (Today)',
    'Send confirmation email to client - Emily (Tomorrow)'
  ],
  transcript: 'Let us discuss client billing and payment delays. We have enabled instant settlements via JazzCash and Easypaisa. The pricing has been confirmed and the client approved the payment schedule.'
};`;

if (code.includes(targetSampleMeeting)) {
  code = code.replace(targetSampleMeeting, demoCommercialMeeting);
}

// 2. In initFirebaseIntegration under isGuest, seed meetings if empty
const oldGuestBlock = `  // Demo Guest Sandbox Mode: local-only, no cloud subscriptions, no cloud writes
  if (isGuest) {
    console.log('Demo Reviewer Sandbox Mode Active (Local Storage Only)');
    currentUser = {
      name: 'Demo Reviewer',
      email: 'demo@meetmind.ai',
      uid: 'demo_guest_evaluator',
      isGuest: true
    };
    initUserProfile();
    updateConnectionStatusUI();
    return;
  }`;

const newGuestBlock = `  // Demo Guest Sandbox Mode: local-only, no cloud subscriptions, no cloud writes
  if (isGuest) {
    console.log('Demo Reviewer Sandbox Mode Active (Local Storage Only)');
    currentUser = {
      name: 'Demo Reviewer',
      email: 'demo@meetmind.ai',
      uid: 'demo_guest_evaluator',
      isGuest: true
    };
    if (meetings.length === 0) {
      meetings = [DEMO_SAMPLE_MEETING, DEMO_COMMERCIAL_MEETING];
      tasks = [DEMO_SAMPLE_TASK];
      persistData();
      renderMeetings();
      renderMeetingsTable();
      renderTasks();
      updateStats();
      populateComparisonSelectors();
    }
    initUserProfile();
    updateConnectionStatusUI();
    return;
  }`;

if (code.includes(oldGuestBlock)) {
  code = code.replace(oldGuestBlock, newGuestBlock);
}

fs.writeFileSync('app.js', code, 'utf8');
console.log('Successfully updated app.js with DEMO_COMMERCIAL_MEETING and guest seeding!');

