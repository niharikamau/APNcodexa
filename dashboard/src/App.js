import React, { useState } from "react";

function App() {
  const [alerts, setAlerts] = useState([
    { id: 1, location: "Room 101", status: "Pending" },
    { id: 2, location: "Room 202", status: "Pending" }
  ]);

  const resolveAlert = (id) => {
    setAlerts(alerts.map(alert =>
      alert.id === id ? { ...alert, status: "Resolved" } : alert
    ));
  };

  return (
    <div style={{ padding: "20px" }}>
      <h1>🚨 Emergency Dashboard</h1>

      {alerts.map(alert => (
        <div key={alert.id} style={{
          border: "1px solid black",
          padding: "10px",
          margin: "10px",
          borderRadius: "10px"
        }}>
          <p><b>ID:</b> {alert.id}</p>
          <p><b>Location:</b> {alert.location}</p>
          <p><b>Status:</b> {alert.status}</p>

          {alert.status === "Pending" && (
            <button onClick={() => resolveAlert(alert.id)}>
              Resolve
            </button>
          )}
        </div>
      ))}
    </div>
  );
}

export default App;