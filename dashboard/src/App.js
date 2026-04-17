import { useEffect, useState } from "react";
import { db } from "./firebase";
import { collection, onSnapshot, doc, updateDoc } from "firebase/firestore";

function App() {
  const [alerts, setAlerts] = useState([]);
  const [filter, setFilter] = useState("all"); // 🔥 filter state

  // 🔥 Fetch data
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

  // 🔥 Resolve function
  const handleResolve = async (id) => {
    try {
      const ref = doc(db, "emergency_requests", id);

      await updateDoc(ref, {
        status: "resolved",
      });
    } catch (error) {
      console.log(error);
    }
  };

  // 🔥 Filtered data
  const filteredAlerts = alerts.filter((alert) => {
    if (filter === "all") return true;
    return alert.status === filter;
  });

  return (
    <div style={{ padding: "20px", fontFamily: "Arial" }}>
      <h1 style={{ textAlign: "center" }}>🚨 Emergency Dashboard</h1>

      {/* 🔥 FILTER BUTTONS */}
      <div style={{ textAlign: "center", marginBottom: "20px" }}>
        <button onClick={() => setFilter("all")} style={{ margin: "5px" }}>
          All
        </button>
        <button onClick={() => setFilter("pending")} style={{ margin: "5px" }}>
          Pending
        </button>
        <button onClick={() => setFilter("resolved")} style={{ margin: "5px" }}>
          Resolved
        </button>
      </div>

      {filteredAlerts.length === 0 ? (
        <p style={{ textAlign: "center" }}>No alerts found</p>
      ) : (
        <div style={{ display: "flex", flexWrap: "wrap", gap: "15px" }}>
          {filteredAlerts.map((alert) => (
            <div
              key={alert.id}
              style={{
                width: "300px",
                borderRadius: "10px",
                padding: "15px",
                backgroundColor:
                  alert.status === "pending" ? "#ffe6e6" : "#e6ffe6",
                border:
                  alert.status === "pending"
                    ? "2px solid red"
                    : "2px solid green",
                boxShadow: "0 4px 8px rgba(0,0,0,0.2)",
              }}
            >
              <h3>
                🚑 {alert.serviceType || "Unknown Service"}
              </h3>

              <p><b>User:</b> {alert.userId}</p>

              {/* 📍 MAP LINK */}
              <p>
                <b>Location:</b>{" "}
                {alert.location ? (
                  <a
                    href={`https://www.google.com/maps?q=${
                      alert.location.latitude || alert.location._lat
                    },${
                      alert.location.longitude || alert.location._long
                    }`}
                    target="_blank"
                    rel="noreferrer"
                  >
                    View on Map 📍
                  </a>
                ) : (
                  "Not available"
                )}
              </p>

              <p>
                <b>Status:</b>{" "}
                <span
                  style={{
                    color:
                      alert.status === "pending" ? "red" : "green",
                    fontWeight: "bold",
                  }}
                >
                  {alert.status}
                </span>
              </p>

              {/* 🔥 BUTTON */}
              {alert.status === "pending" ? (
                <button
                  onClick={() => handleResolve(alert.id)}
                  style={{
                    marginTop: "10px",
                    padding: "8px 12px",
                    backgroundColor: "red",
                    color: "white",
                    border: "none",
                    borderRadius: "5px",
                    cursor: "pointer",
                  }}
                >
                  Resolve
                </button>
              ) : (
                <button
                  disabled
                  style={{
                    marginTop: "10px",
                    padding: "8px 12px",
                    backgroundColor: "gray",
                    color: "white",
                    border: "none",
                    borderRadius: "5px",
                  }}
                >
                  Resolved
                </button>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

export default App;