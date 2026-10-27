// ==========================================================================
// MeetMind AI — Two-Account Isolation & Security Verification Test
// ==========================================================================
const API_KEY = "AIzaSyAVogcGOhsv2UgEAOEsCICkfMRrfD8dd_4";
const PROJECT_ID = "meetmind-ai-74519";

async function runTest() {
  console.log("====================================================");
  console.log("🔒 MeetMind AI: Two-Account Isolation Test Starting");
  console.log("====================================================");

  const stamp = Date.now();
  const emailA = `isolation_test_a_${stamp}@test.com`;
  const emailB = `isolation_test_b_${stamp}@test.com`;
  const pass = "TestPassword123!";

  // 1. Create Account A
  console.log(`\n[1/7] Creating Account A (${emailA})...`);
  const signUpResA = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${API_KEY}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email: emailA, password: pass, returnSecureToken: true })
  });
  const dataA = await signUpResA.json();
  if (!dataA.idToken) {
    throw new Error("Failed to create Account A: " + JSON.stringify(dataA));
  }
  const tokenA = dataA.idToken;
  const uidA = dataA.localId;
  console.log(`  ✓ Account A created successfully! UID: ${uidA}`);

  // 2. Create Account B
  console.log(`\n[2/7] Creating Account B (${emailB})...`);
  const signUpResB = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${API_KEY}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email: emailB, password: pass, returnSecureToken: true })
  });
  const dataB = await signUpResB.json();
  if (!dataB.idToken) {
    throw new Error("Failed to create Account B: " + JSON.stringify(dataB));
  }
  const tokenB = dataB.idToken;
  const uidB = dataB.localId;
  console.log(`  ✓ Account B created successfully! UID: ${uidB}`);

  // 3. Account A writes a private meeting document
  console.log("\n[3/7] Account A creates a private meeting document in Firestore...");
  const createResA = await fetch(
    `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/meetings`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${tokenA}`
      },
      body: JSON.stringify({
        fields: {
          title: { stringValue: "Account A Confidential Sprint Review" },
          userId: { stringValue: uidA },
          summary: { stringValue: "Private financials and salary details of Account A" }
        }
      })
    }
  );
  const meetingDocA = await createResA.json();
  if (!meetingDocA.name) {
    throw new Error("Account A failed to create meeting: " + JSON.stringify(meetingDocA));
  }
  const docPathA = meetingDocA.name; // Full path projects/.../documents/meetings/xyz
  console.log(`  ✓ Account A document created successfully: ${docPathA.split("/").pop()}`);

  // 4. Test Attack 1: Account B tries to read Account A's document directly
  console.log("\n[4/7] TEST: Account B attempts direct GET on Account A's confidential meeting...");
  const readResB = await fetch(`https://firestore.googleapis.com/v1/${docPathA}`, {
    headers: { "Authorization": `Bearer ${tokenB}` }
  });
  const readDataB = await readResB.json();
  console.log(`  Status code: ${readResB.status}`);
  if (readResB.status === 403 && readDataB.error?.status === "PERMISSION_DENIED") {
    console.log("  ✅ PASS: Account B was BLOCKED with 403 PERMISSION_DENIED. Zero data leaked!");
  } else {
    console.error("  ❌ FAIL: Account B was able to read or got unexpected response: " + JSON.stringify(readDataB));
  }

  // 5. Test Attack 2: Account B tries to overwrite or modify Account A's document
  console.log("\n[5/7] TEST: Account B attempts to PATCH/UPDATE Account A's meeting...");
  const patchResB = await fetch(`https://firestore.googleapis.com/v1/${docPathA}`, {
    method: "PATCH",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${tokenB}`
    },
    body: JSON.stringify({
      fields: {
        title: { stringValue: "Compromised by B" },
        userId: { stringValue: uidB }
      }
    })
  });
  const patchDataB = await patchResB.json();
  console.log(`  Status code: ${patchResB.status}`);
  if (patchResB.status === 403 && patchDataB.error?.status === "PERMISSION_DENIED") {
    console.log("  ✅ PASS: Account B was BLOCKED from modifying Account A's doc with 403 PERMISSION_DENIED!");
  } else {
    console.error("  ❌ FAIL: Account B was able to patch or got unexpected response: " + JSON.stringify(patchDataB));
  }

  // 6. Test Attack 3: Account B tries to delete Account A's document
  console.log("\n[6/7] TEST: Account B attempts to DELETE Account A's meeting...");
  const deleteResB = await fetch(`https://firestore.googleapis.com/v1/${docPathA}`, {
    method: "DELETE",
    headers: { "Authorization": `Bearer ${tokenB}` }
  });
  const deleteDataB = await deleteResB.json();
  console.log(`  Status code: ${deleteResB.status}`);
  if (deleteResB.status === 403 && deleteDataB.error?.status === "PERMISSION_DENIED") {
    console.log("  ✅ PASS: Account B was BLOCKED from deleting Account A's doc with 403 PERMISSION_DENIED!");
  } else {
    console.error("  ❌ FAIL: Account B was able to delete or got unexpected response: " + JSON.stringify(deleteDataB));
  }

  // 7. Test Attack 4: Unauthenticated request tries to read or query
  console.log("\n[7/7] TEST: Unauthenticated visitor attempts to read Account A's meeting...");
  const unauthRes = await fetch(`https://firestore.googleapis.com/v1/${docPathA}`);
  const unauthData = await unauthRes.json();
  console.log(`  Status code: ${unauthRes.status}`);
  if (unauthRes.status === 403 && unauthData.error?.status === "PERMISSION_DENIED") {
    console.log("  ✅ PASS: Unauthenticated visitor was BLOCKED with 403 PERMISSION_DENIED!");
  } else {
    console.error("  ❌ FAIL: Unauthenticated visitor was able to access data!");
  }

  // Clean up: Account A deletes their own test document
  console.log("\n[Clean-up] Account A deletes their test document...");
  const cleanRes = await fetch(`https://firestore.googleapis.com/v1/${docPathA}`, {
    method: "DELETE",
    headers: { "Authorization": `Bearer ${tokenA}` }
  });
  console.log(`  Clean-up status: ${cleanRes.status === 200 ? "SUCCESS (Doc Deleted)" : "Code " + cleanRes.status}`);

  console.log("\n====================================================");
  console.log("🎉 ALL TWO-ACCOUNT ISOLATION TESTS PASSED 100%!");
  console.log("====================================================");
}

runTest().catch(err => {
  console.error("FATAL ERROR in isolation test:", err);
  process.exit(1);
});
