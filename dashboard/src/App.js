import { useEffect, useState } from "react";
import { db } from "./firebase";
import { collection, onSnapshot, doc, updateDoc } from "firebase/firestore";

function App() {
  const [alerts, setAlerts] = useState([]);

  // ✅ Fetch data from Firestore
  useEffect(() => {
    const unsubscribe = onSnapshot(
      collection(db, "emergency_requests"),
      (snapshot) => {
        const data = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }));

        setAlerts(data);
      }
    );

    return () => unsubscribe();
  }, []);

  // ✅ Resolve function (MUST be outside useEffect)
  const handleResolve = async (id) => {
    try {
      const ref = doc(db, "emergency_requests", id);

      await updateDoc(ref, {
        status: "resolved",
      });

      console.log("Updated successfully");
    } catch (error) {
      console.log(error);
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
              padding: "10px",
            }}
          >
            <p><b>Service:</b> {alert.serviceType}</p>
            <p><b>User:</b> {alert.userId}</p>
            <p>
              <b>Location:</b> {alert.location?.latitude},{" "}
              {alert.location?.longitude}
            </p>

            <p>
              <b>Status:</b>{" "}
              <span style={{ color: alert.status === "pending" ? "red" : "green" }}>
                {alert.status}
              </span>
            </p>

            {/* ✅ Button Logic */}
            {alert.status === "pending" ? (
              <button onClick={() => handleResolve(alert.id)}>
                Resolve
              </button>
            ) : (
              <button
                disabled
                style={{ backgroundColor: "gray", color: "white" }}
              >
                Resolved
              </button>
            )}
          </div>
        ))
      )}
    </div>
  );
}

export default App;