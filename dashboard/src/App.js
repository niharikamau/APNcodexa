import { useEffect, useState } from "react";
import { db } from "./firebase";
import { collection, onSnapshot, doc, updateDoc } from "firebase/firestore";

function App() {
  const [alerts, setAlerts] = useState([]);

  useEffect(() => {
    const unsubscribe = onSnapshot(
      collection(db, "emergency_requests"),
      (snapshot) => {
        const data = snapshot.docs.map(doc => ({
          id: doc.id,
          ...doc.data()
        }));
        setAlerts(data);
      }
    );

    return () => unsubscribe();
  }, []);

  // 🔥 Resolve function
  const handleResolve = async (id) => {
    try {
      await updateDoc(doc(db, "emergency_requests", id), {
        status: "resolved"
      });
    } catch (error) {
      console.error("Error updating status:", error);
    }
  };

  return (
    <div style={{ padding: "20px" }}>
      <h1>🚨 Emergency Dashboard</h1>

      {alerts.length === 0 ? (
        <p>No alerts yet</p>
      ) : (
        alerts.map((alert) => (
          <div
            key={alert.id}
            style={{
              border: "1px solid black",
              margin: "10px",
              padding: "10px"
            }}
          >
            <p><b>Service:</b> {alert.serviceType}</p>
            <p><b>User:</b> {alert.userId}</p>

            <p>
              <b>Location:</b>{" "}
              {alert.location
                ? `${alert.location.latitude || alert.location._lat}, ${
                    alert.location.longitude || alert.location._long
                  }`
                : "Not available"}
            </p>

            <p><b>Status:</b> {alert.status}</p>

            {/* 🔥 Resolve Button */}
           <button onClick={() => handleResolve(alert.id)}>
  Resolve
</button>
          </div>
        ))
      )}
    </div>
  );
}

export default App;