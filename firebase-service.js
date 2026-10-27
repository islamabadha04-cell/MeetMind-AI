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
  onAuthStateChanged 
} from "https://www.gstatic.com/firebasejs/10.11.0/firebase-auth.js";
import { 
  getFirestore, 
  collection, 
  addDoc, 
  getDocs, 
  onSnapshot, 
  query, 
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

// Your exact Firebase configuration
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

// Initialize Analytics if supported in this environment
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
      return { success: true, user: res.user };
    } catch (err) {
      console.warn("Google sign-in error:", err);
      return { success: false, error: err.message };
    }
  },

  logout: async () => {
    try {
      await signOut(auth);
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

  // 2. Firestore Meetings
  saveMeeting: async (meetingData) => {
    try {
      const col = collection(db, "meetings");
      const docRef = await addDoc(col, {
        ...meetingData,
        userId: window.MeetMindFirebase.currentUser?.uid || "guest",
        createdAt: serverTimestamp()
      });
      return { success: true, id: docRef.id };
    } catch (err) {
      console.warn("Firestore save meeting fallback:", err);
      return { success: false, error: err.message };
    }
  },

  subscribeMeetings: (callback) => {
    try {
      const col = collection(db, "meetings");
      const q = query(col, orderBy("createdAt", "desc"));
      return onSnapshot(q, (snapshot) => {
        const list = [];
        snapshot.forEach((doc) => {
          list.push({ id: doc.id, ...doc.data() });
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

  // 3. Firestore Tasks
  saveTask: async (taskData) => {
    try {
      const col = collection(db, "tasks");
      const docRef = await addDoc(col, {
        ...taskData,
        userId: window.MeetMindFirebase.currentUser?.uid || "guest",
        createdAt: serverTimestamp()
      });
      return { success: true, id: docRef.id };
    } catch (err) {
      return { success: false, error: err.message };
    }
  },

  subscribeTasks: (callback) => {
    try {
      const col = collection(db, "tasks");
      const q = query(col, orderBy("createdAt", "desc"));
      return onSnapshot(q, (snapshot) => {
        const list = [];
        snapshot.forEach((doc) => {
          list.push({ id: doc.id, ...doc.data() });
        });
        callback(list);
      }, (err) => {
        console.warn("Firestore tasks subscription notice:", err);
      });
    } catch (err) {
      console.warn("Firestore task subscription error:", err);
    }
  },

  // 4. Cloud Storage (Audio Upload)
  uploadAudioBlob: async (audioBlob, fileName) => {
    try {
      const fileRef = storageRef(storage, `recordings/${Date.now()}_${fileName || 'meeting.webm'}`);
      const uploadRes = await uploadBytes(fileRef, audioBlob);
      const downloadUrl = await getDownloadURL(uploadRes.ref);
      return { success: true, downloadUrl };
    } catch (err) {
      console.warn("Firebase audio upload fallback:", err);
      return { success: false, error: err.message };
    }
  }
};

console.log("🔥 MeetMind AI Firebase Cloud Services Initialized for project: meetmind-ai-74519");
