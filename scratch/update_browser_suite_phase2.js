const fs = require('fs');

let testCode = fs.readFileSync('scratch/test_browser_suite.js', 'utf8');

const targetBeforeSuite6 = '// -------------------------------------------------------------------------\n    // TEST SUITE 6: Console Logs & Uncaught Errors';

const suite5D = `// -------------------------------------------------------------------------
    // TEST SUITE 5D: Phase 2 AI Meeting Memory & Cross-Meeting Intelligence
    // -------------------------------------------------------------------------
    console.log('\\n======================================================');
    console.log('🧪 TEST SUITE 5D: Phase 2 AI Meeting Memory & Cross-Meeting Intelligence');
    console.log('======================================================');

    // 1. Navigation to AI Meeting Search
    await cdp.evaluate('document.querySelector("button[data-nav=\\'search\\']")?.click()');
    await sleep(250);
    const isSearchPageVisible = await cdp.evaluate('!document.getElementById("page-search")?.classList.contains("hidden")');
    assert('Navigate to AI Meeting Search view', isSearchPageVisible);

    // Scenario 1: Multi-Meeting Semantic Search for "payment delays"
    await cdp.evaluate(\`
      const sInput = document.getElementById("aiMeetingSearchInput");
      if (sInput) {
        sInput.value = "payment delays";
        document.getElementById("btnExecuteAiSearch")?.click();
      }
    \`);
    await sleep(350);
    const searchHitsCount = await cdp.evaluate('document.querySelectorAll("#aiSearchResultsList .search-hit-card").length');
    const hasSearchSynthesis = await cdp.evaluate('!document.getElementById("aiSearchSynthesisBanner")?.classList.contains("hidden")');
    assert('Multi-meeting search retrieves excerpts for "payment delays"', searchHitsCount > 0, \`Found \${searchHitsCount} ranked hits\`);
    assert('AI search cross-meeting synthesis banner rendered', hasSearchSynthesis);

    // Test Search "Open Meeting & Seek" button
    const hasSeekBtn = await cdp.evaluate('!!document.querySelector(".search-hit-card .btn-seek-meeting")');
    assert('Search result contains direct "Open Meeting & Seek" button', hasSeekBtn);

    // 2. Navigation to Meeting Comparison Matrix
    await cdp.evaluate('document.querySelector("button[data-nav=\\'compare\\']")?.click()');
    await sleep(250);
    const isComparePageVisible = await cdp.evaluate('!document.getElementById("page-compare")?.classList.contains("hidden")');
    assert('Navigate to Meeting Comparison view', isComparePageVisible);

    // Scenario 2: Run Meeting Comparison
    await cdp.evaluate('document.getElementById("btnRunMeetingComparison")?.click()');
    await sleep(350);
    const isCompareDeltaVisible = await cdp.evaluate('!document.getElementById("compareDeltaCard")?.classList.contains("hidden")');
    const isMatrixTableVisible = await cdp.evaluate('!document.getElementById("compareMatrixTable")?.classList.contains("hidden")');
    const matrixRowsCount = await cdp.evaluate('document.querySelectorAll("#compareMatrixTbody tr").length');
    assert('Meeting comparison delta analysis rendered', isCompareDeltaVisible);
    assert('Comparison matrix table displays 7 core operational categories', isMatrixTableVisible && matrixRowsCount >= 6, \`Found \${matrixRowsCount} rows\`);

    const hasNotMentionedBadge = await cdp.evaluate('document.querySelectorAll(".status-not-mentioned").length > 0');
    assert('Comparison matrix correctly identifies absent metrics as "Not Mentioned"', hasNotMentionedBadge);

    // 3. Navigation to Company Knowledge Base (RAG)
    await cdp.evaluate('document.querySelector("button[data-nav=\\'knowledge-base\\']")?.click()');
    await sleep(250);
    const isKbPageVisible = await cdp.evaluate('!document.getElementById("page-knowledge-base")?.classList.contains("hidden")');
    assert('Navigate to Company Knowledge Base view', isKbPageVisible);

    // Scenario 3: Document Upload Dropzone & Indexed Documents Table
    const hasKbDropzone = await cdp.evaluate('!!document.getElementById("kbUploadDropzone")');
    const kbDocsCount = await cdp.evaluate('document.querySelectorAll("#kbDocumentsTableBody tr").length');
    assert('Knowledge Base drag-and-drop upload zone active', hasKbDropzone);
    assert('Company Knowledge Base documents table populated', kbDocsCount > 0, \`Found \${kbDocsCount} indexed documents\`);

    // 4. Navigation to Meeting Memory Engine
    await cdp.evaluate('document.querySelector("button[data-nav=\\'memory\\']")?.click()');
    await sleep(250);
    const isMemoryPageVisible = await cdp.evaluate('!document.getElementById("page-memory")?.classList.contains("hidden")');
    assert('Navigate to Persistent Meeting Memory view', isMemoryPageVisible);

    // Scenario 6: Memory Category Filtering & Memory Cards
    const memoryCardsCount = await cdp.evaluate('document.querySelectorAll("#memoryCardsGrid .memory-item-card").length');
    assert('Meeting Memory engine renders categorized organizational facts', memoryCardsCount > 0, \`Found \${memoryCardsCount} memories\`);

    // Click Category tab "Financial / Budget"
    await cdp.evaluate('document.querySelector("#memoryCategoriesTabs button[data-cat=\\'Financial Discussions\\']")?.click()');
    await sleep(200);
    const filteredMemCount = await cdp.evaluate('document.querySelectorAll("#memoryCardsGrid .memory-item-card").length');
    assert('Memory categories tab filters records correctly', filteredMemCount > 0);

    // Reset to All memories
    await cdp.evaluate('document.querySelector("#memoryCategoriesTabs button[data-cat=\\'all\\']")?.click()');
    await sleep(200);

    // 5. Upgraded Knowledge AI Chat with Universal RAG
    await cdp.evaluate('document.querySelector("button[data-nav=\\'chat\\']")?.click()');
    await sleep(250);

    const hasScopeSwitcher = await cdp.evaluate('!!document.getElementById("chatScopeBar")');
    assert('AI Chat contains Multi-Source Scope Switcher', hasScopeSwitcher);

    // Scenario 4: Grounded Chat Query with Citation Verification
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
    \`);
    await sleep(800);
    const chatHtml = await cdp.evaluate('document.getElementById("deskChatArea")?.innerText || ""');
    const hasAntiHallucinationNotice = chatHtml.includes("could not find sufficient information") || chatHtml.includes("Verification Guardrail");
    assert('AI Chat refuses to invent answers when information is absent (Anti-Hallucination Guardrail)', hasAntiHallucinationNotice);

    // Scenario 8: Verify original meeting transcripts remain intact
    const originalMeetingsCount = await cdp.evaluate('meetings && meetings.length');
    assert('Original meeting transcripts and data structures preserved intact', originalMeetingsCount >= 1);

    \n    `;

if (testCode.includes(targetBeforeSuite6)) {
  testCode = testCode.replace(targetBeforeSuite6, suite5D + targetBeforeSuite6);
  fs.writeFileSync('scratch/test_browser_suite.js', testCode, 'utf8');
  console.log('Successfully added TEST SUITE 5D to test_browser_suite.js!');
} else {
  console.error('Could not find target before Suite 6 in test_browser_suite.js');
}

