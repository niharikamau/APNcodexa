import { useEffect, useState } from "react";
import { db } from "./firebase";
import { collection, onSnapshot } from "firebase/firestore";

function App() {
  const [alerts, setAlerts] = useState([]);

  useEffect(() => {
    const unsubscribe = onSnapshot(
      collection(db, "emergency_requests"),
      (snapshot) => {
        const data = snapshot.docs.map(doc => doc.data());
        setAlerts(data);
      }
    );

    return () => unsubscribe();
  }, []);

  return (
    <div style={{ padding: "20px" }}>
      <h1>🚨 Emergency Dashboard</h1>

      {alerts.length === 0 ? (
        <p>No alerts yet</p>
      ) : (
        alerts.map((alert, index) => (
          <div key={index} style={{ border: "1px solid black", margin: "10px", padding: "10px" }}>
            <p><b>Service:</b> {alert.serviceType}</p>
            <p><b>User:</b> {alert.userId}</p>
            <p>
  <b>Location:</b> {alert.location?.latitude}, {alert.location?.longitude}
</p>
            <p><b>Status:</b> {alert.status}</p>
          </div>
        ))
      )}
    </div>
  );
}

export default App;