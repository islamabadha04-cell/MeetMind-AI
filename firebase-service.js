// ==========================================================================
// MeetMind AI — Firebase Cloud Services (Auth, Firestore, Storage)
// Project: meetmind-ai-74519
// ==========================================================================

import { initializeApp } from "https://www.gstatic.com/firebasejs/10.11.0/firebase-app.js";
import { getAnalytics, isSupported as isAnalyticsSupported } from "https://www.gstatic.com/firebasejs/10.11.0/firebase-analytics.js";
import { 
  getAuth, 
  GoogleAuthProvider, 
  signInWithPopup, 
  signInWithEmailAndPassword, 
  createUserWithEmailAndPassword, 
  signOut, 
  sendPasswordResetEmail,
  onAuthStateChanged 
} from "https://www.gstatic.com/firebasejs/10.11.0/firebase-auth.js";
import { 
  getFirestore, 
  collection, 
  addDoc, 
  getDocs, 
  onSnapshot, 
  query, 
  where,
  orderBy, 
  doc, 
  deleteDoc, 
  updateDoc, 
  serverTimestamp 
} from "https://www.gstatic.com/firebasejs/10.11.0/firebase-firestore.js";
import { 
  getStorage, 
  ref as storageRef, 
  uploadBytes, 
  getDownloadURL 
} from "https://www.gstatic.com/firebasejs/10.11.0/firebase-storage.js";

// Exact Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyAVogcGOhsv2UgEAOEsCICkfMRrfD8dd_4",
  authDomain: "meetmind-ai-74519.firebaseapp.com",
  projectId: "meetmind-ai-74519",
  storageBucket: "meetmind-ai-74519.firebasestorage.app",
  messagingSenderId: "790778332182",
  appId: "1:790778332182:web:b4a2c8ebbd8720a61f6137",
  measurementId: "G-GKBBKE3046"
};

// Initialize Firebase App
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);
const storage = getStorage(app);
const googleProvider = new GoogleAuthProvider();

// Initialize Analytics if supported
let analytics = null;
isAnalyticsSupported().then(supported => {
  if (supported) {
    analytics = getAnalytics(app);
    window.MeetMindFirebase.analytics = analytics;
    console.log("📊 Firebase Analytics Initialized");
  }
}).catch(err => {
  console.log("Analytics not supported in current environment:", err);
});

// Exported Service Object attached to window for seamless integration
window.MeetMindFirebase = {
  app,
  analytics,
  auth,
  db,
  storage,
  currentUser: null,

  // 1. Authentication
  loginWithGoogle: async () => {
    try {
      const res = await signInWithPopup(auth, googleProvider);
      window.MeetMindFirebase.currentUser = res.user;
      return { success: true, user: res.user };
    } catch (err) {
      console.warn("Google sign-in error:", err);
      return { success: false, error: err.message };
    }
  },

  loginWithEmail: async (email, password) => {
    try {
      const res = await signInWithEmailAndPassword(auth, email, password);
      window.MeetMindFirebase.currentUser = res.user;
      return { success: true, user: res.user };
    } catch (err) {
      return { success: false, error: err.message };
    }
  },

  registerWithEmail: async (email, password) => {
    try {
      const res = await createUserWithEmailAndPassword(auth, email, password);
      window.MeetMindFirebase.currentUser = res.user;
      return { success: true, user: res.user };
    } catch (err) {
      return { success: false, error: err.message };
    }
  },

  resetPassword: async (email) => {
    try {
      await sendPasswordResetEmail(auth, email);
      return { success: true };
    } catch (err) {
      return { success: false, error: err.message };
    }
  },

  logout: async () => {
    try {
      await signOut(auth);
      window.MeetMindFirebase.currentUser = null;
      localStorage.removeItem('meetmind_user');
      sessionStorage.removeItem('meetmind_guest_session');
      return { success: true };
    } catch (err) {
      return { success: false, error: err.message };
    }
  },

  onAuthUpdate: (callback) => {
    onAuthStateChanged(auth, (user) => {
      window.MeetMindFirebase.currentUser = user;
      callback(user);
    });
  },

  // 2. Firestore Meetings (Strictly isolated by userId)
  saveMeeting: async (meetingData) => {
    const user = window.MeetMindFirebase.currentUser;
    if (!user || user.isGuest) {
      return { success: false, error: "Must be signed in to sync to cloud" };
    }
    try {
      const col = collection(db, "meetings");
      const docRef = await addDoc(col, {
        ...meetingData,
        userId: user.uid,
        createdAt: serverTimestamp()
      });
      return { success: true, id: docRef.id };
    } catch (err) {
      console.warn("Firestore save meeting error:", err);
      return { success: false, error: err.message };
    }
  },

  subscribeMeetings: (userId, callback) => {
    if (!userId || userId === 'demo_guest_evaluator') {
      callback([]);
      return () => {};
    }
    try {
      const col = collection(db, "meetings");
      // Query restricted strictly to this authenticated user
      const q = query(col, where("userId", "==", userId));
      return onSnapshot(q, (snapshot) => {
        const list = [];
        snapshot.forEach((docSnap) => {
          list.push({ id: docSnap.id, ...docSnap.data() });
        });
        // Sort newest first client-side to prevent missing index errors
        list.sort((a, b) => {
          const tA = a.createdAt?.toMillis ? a.createdAt.toMillis() : (a.timestamp || 0);
          const tB = b.createdAt?.toMillis ? b.createdAt.toMillis() : (b.timestamp || 0);
          return tB - tA;
        });
        callback(list);
      }, (err) => {
        console.warn("Firestore meetings subscription notice:", err);
      });
    } catch (err) {
      console.warn("Firestore subscription error:", err);
    }
  },

  deleteMeeting: async (docId) => {
    try {
      await deleteDoc(doc(db, "meetings", docId));
      return { success: true };
    } catch (err) {
      return { success: false, error: err.message };
    }
  },

  // 3. Firestore Tasks (Strictly isolated by userId)
  saveTask: async (taskData) => {
    const user = window.MeetMindFirebase.currentUser;
    if (!user || user.isGuest) {
      return { success: false, error: "Must be signed in to sync to cloud" };
    }
    try {
      const col = collection(db, "tasks");
      const docRef = await addDoc(col, {
        ...taskData,
        userId: user.uid,
        createdAt: serverTimestamp()
      });
      return { success: true, id: docRef.id };
    } catch (err) {
      return { success: false, error: err.message };
    }
  },

  subscribeTasks: (userId, callback) => {
    if (!userId || userId === 'demo_guest_evaluator') {
      callback([]);
      return () => {};
    }
    try {
      const col = collection(db, "tasks");
      const q = query(col, where("userId", "==", userId));
      return onSnapshot(q, (snapshot) => {
        const list = [];
        snapshot.forEach((docSnap) => {
          list.push({ id: docSnap.id, ...docSnap.data() });
        });
        list.sort((a, b) => (b.id || 0) - (a.id || 0));
        callback(list);
      }, (err) => {
        console.warn("Firestore tasks subscription notice:", err);
      });
    } catch (err) {
      console.warn("Firestore task subscription error:", err);
    }
  },

  deleteTask: async (docId) => {
    try {
      await deleteDoc(doc(db, "tasks", docId));
      return { success: true };
    } catch (err) {
      return { success: false, error: err.message };
    }
  },

  // 4. Cloud Storage (Audio Upload Scoped by User ID)
  uploadAudioBlob: async (audioBlob, fileName) => {
    const user = window.MeetMindFirebase.currentUser;
    if (!user || user.isGuest) {
      return { success: false, error: "Must be signed in with a real account to upload audio to cloud" };
    }
    const uid = user.uid;
    try {
      const fileRef = storageRef(storage, `recordings/${uid}/${Date.now()}_${fileName || 'meeting.webm'}`);
      const uploadRes = await uploadBytes(fileRef, audioBlob);
      const downloadUrl = await getDownloadURL(uploadRes.ref);
      return { success: true, downloadUrl };
    } catch (err) {
      console.warn("Firebase audio upload error:", err);
      return { success: false, error: err.message };
    }
  }
};

export { 
  app, 
  auth, 
  db, 
  storage, 
  googleProvider, 
  signInWithPopup, 
  signInWithEmailAndPassword, 
  createUserWithEmailAndPassword,
  sendPasswordResetEmail,
  signOut 
};

console.log("🔥 MeetMind AI Firebase Cloud Services Initialized (User-Scoped Isolation)");
