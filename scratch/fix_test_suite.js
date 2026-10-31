const fs = require('fs');

let testCode = fs.readFileSync('scratch/test_browser_suite.js', 'utf8');

// Fix chatInp declarations with IIFEs
testCode = testCode.replace(`    // Scenario 4: Grounded Chat Query with Citation Verification
    await cdp.evaluate(\`
      const chatInp = document.getElementById("deskChatQueryInput");
      if (chatInp) {
        chatInp.value = "What payment terms were agreed with the client?";
        document.getElementById("deskChatSendBtn")?.click();
      }
    \`);
    await sleep(800);
    const hasCitationsInChat = await cdp.evaluate('document.querySelectorAll(".citation-pill").length > 0');
    assert('AI Chat provides verified source citations with timestamps/pages', hasCitationsInChat);

    // Scenario 5: Anti-Hallucination Guardrail Check for Unrelated Question
    await cdp.evaluate(\`
      const chatInp = document.getElementById("deskChatQueryInput");
      if (chatInp) {
        chatInp.value = "What is the capital city of planet Neptune?";
        document.getElementById("deskChatSendBtn")?.click();
      }
    \`);`, `    // Scenario 4: Grounded Chat Query with Citation Verification
    await cdp.evaluate(\`
      (() => {
        const inp = document.getElementById("deskChatQueryInput");
        if (inp) {
          inp.value = "What payment terms were agreed with the client?";
          document.getElementById("deskChatSendBtn")?.click();
        }
      })()
    \`);
    await sleep(800);
    const hasCitationsInChat = await cdp.evaluate('document.querySelectorAll(".citation-pill").length > 0');
    assert('AI Chat provides verified source citations with timestamps/pages', hasCitationsInChat);

    // Scenario 5: Anti-Hallucination Guardrail Check for Unrelated Question
    await cdp.evaluate(\`
      (() => {
        const inp = document.getElementById("deskChatQueryInput");
        if (inp) {
          inp.value = "What is the capital city of planet Neptune?";
          document.getElementById("deskChatSendBtn")?.click();
        }
      })()
    \`);`);

// In Suite 5D, before running search or compare, make sure demo meetings exist in state
const targetSuite5DStart = `    // 1. Navigation to AI Meeting Search
    await cdp.evaluate('document.querySelector("button[data-nav=\\'search\\']")?.click()');`;

const upgradedSuite5DStart = `    // Ensure demo meetings are populated in guest state if needed
    await cdp.evaluate(\`
      if (meetings.length < 2 && typeof DEMO_SAMPLE_MEETING !== 'undefined' && typeof DEMO_COMMERCIAL_MEETING !== 'undefined') {
        meetings = [DEMO_SAMPLE_MEETING, DEMO_COMMERCIAL_MEETING];
        persistData();
        renderMeetings();
        renderMeetingsTable();
        populateComparisonSelectors();
      }
    \`);
    await sleep(200);

    // 1. Navigation to AI Meeting Search
    await cdp.evaluate('document.querySelector("button[data-nav=\\'search\\']")?.click()');`;

if (testCode.includes(targetSuite5DStart)) {
  testCode = testCode.replace(targetSuite5DStart, upgradedSuite5DStart);
}

fs.writeFileSync('scratch/test_browser_suite.js', testCode, 'utf8');
console.log('Successfully updated scratch/test_browser_suite.js!');

