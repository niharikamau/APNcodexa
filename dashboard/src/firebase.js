import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";

const firebaseConfig = {
  apiKey: "AIzaSyBLrqitrNCekF0LFUBqvGQr0h7aR8AVttg",
  authDomain: "crisis-response-system.firebaseapp.com",
  projectId: "crisis-response-system",
  storageBucket: "crisis-response-system.firebasestorage.app",
  messagingSenderId: "53096719736",
  appId: "1:53096719736:web:38b95c20b000ff221b148d",
};

const app = initializeApp(firebaseConfig);

export const db = getFirestore(app);