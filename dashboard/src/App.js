import { useEffect, useRef, useState } from "react";
import { db } from "./firebase";
import {
  collection,
  onSnapshot,
  doc,
  updateDoc,
  runTransaction,
} from "firebase/firestore";

function App() {
  const [alerts, setAlerts] = useState([]);
  const [ambulances, setAmbulances] = useState([]);
  const [policeUnits, setPoliceUnits] = useState([]);
  const [fireUnits, setFireUnits] = useState([]);
  const [statusFilter, setStatusFilter] = useState("all");
  const [urgencyFilter, setUrgencyFilter] = useState("all");

  const audioRef = useRef(null);
  const hasLoadedRef = useRef(false);
  const prevPendingIdsRef = useRef(new Set());
  const assigningIdsRef = useRef(new Set());

  const MAX_DISTANCE_KM = 5;

  const urgencyOrder = {
    CRITICAL: 1,
    HIGH: 2,
    MEDIUM: 3,
    LOW: 4,
  };

  useEffect(() => {
    audioRef.current = new Audio("/alert.mp3");
  }, []);

  useEffect(() => {
    const unsubscribe = onSnapshot(
      collection(db, "emergency_requests"),
      (snapshot) => {
        const data = snapshot.docs.map((docItem) => ({
          id: docItem.id,
          ...docItem.data(),
        }));

        const currentPendingIds = new Set(
          data.filter((item) => item.status === "pending").map((item) => item.id)
        );

        if (hasLoadedRef.current && audioRef.current) {
          let newPendingFound = false;

          currentPendingIds.forEach((id) => {
            if (!prevPendingIdsRef.current.has(id)) {
              newPendingFound = true;
            }
          });

          if (newPendingFound) {
            audioRef.current.currentTime = 0;
            audioRef.current.play().catch(() => {});
          }
        }

        prevPendingIdsRef.current = currentPendingIds;
        hasLoadedRef.current = true;

        setAlerts(data);
      }
    );

    return () => unsubscribe();
  }, []);

  useEffect(() => {
    const unsubAmb = onSnapshot(collection(db, "ambulances"), (snapshot) => {
      const data = snapshot.docs.map((docItem) => ({
        firestoreId: docItem.id,
        ...docItem.data(),
      }));
      setAmbulances(data);
    });

    const unsubPolice = onSnapshot(collection(db, "police_units"), (snapshot) => {
      const data = snapshot.docs.map((docItem) => ({
        firestoreId: docItem.id,
        ...docItem.data(),
      }));
      setPoliceUnits(data);
    });

    const unsubFire = onSnapshot(collection(db, "fire_units"), (snapshot) => {
      const data = snapshot.docs.map((docItem) => ({
        firestoreId: docItem.id,
        ...docItem.data(),
      }));
      setFireUnits(data);
    });

    return () => {
      unsubAmb();
      unsubPolice();
      unsubFire();
    };
  }, []);

  useEffect(() => {
    if (alerts.length === 0) return;

    const sortedAlerts = [...alerts].sort((a, b) => {
      const urgencyA = inferUrgency(a);
      const urgencyB = inferUrgency(b);

      return urgencyOrder[urgencyA] - urgencyOrder[urgencyB];
    });

    sortedAlerts.forEach((alertItem) => {
      const validRequest =
        alertItem.serviceType &&
        alertItem.location &&
        alertItem.location.latitude != null &&
        alertItem.location.longitude != null &&
        alertItem.status === "pending";

      if (!validRequest) return;
      if (alertItem.assignedProviderId) return;
      if (assigningIdsRef.current.has(alertItem.id)) return;

      assigningIdsRef.current.add(alertItem.id);

      autoAssignNearest(alertItem).finally(() => {
        assigningIdsRef.current.delete(alertItem.id);
      });
    });
  }, [alerts, ambulances, policeUnits, fireUnits]);

  const getDistanceKm = (lat1, lon1, lat2, lon2) => {
    const toRad = (value) => (value * Math.PI) / 180;
    const R = 6371;

    const dLat = toRad(lat2 - lat1);
    const dLon = toRad(lon2 - lon1);

    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(toRad(lat1)) *
        Math.cos(toRad(lat2)) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  };

  const getProviderGroup = (serviceType) => {
    const type = (serviceType || "").toLowerCase();

    if (type === "ambulance") {
      return { collectionName: "ambulances", providers: ambulances };
    }

    if (type === "police") {
      return { collectionName: "police_units", providers: policeUnits };
    }

    if (type === "fire" || type === "fire brigade") {
      return { collectionName: "fire_units", providers: fireUnits };
    }

    return { collectionName: "", providers: [] };
  };

  const autoAssignNearest = async (alertItem) => {
    try {
      const { collectionName, providers } = getProviderGroup(alertItem.serviceType);

      if (!collectionName || providers.length === 0) return;

      const availableProviders = providers.filter(
        (provider) =>
          provider.available === true &&
          provider.location &&
          provider.location.latitude != null &&
          provider.location.longitude != null
      );

      if (availableProviders.length === 0) return;

      let nearestProvider = null;
      let minDistance = Infinity;

      availableProviders.forEach((provider) => {
        const distance = getDistanceKm(
          alertItem.location.latitude,
          alertItem.location.longitude,
          provider.location.latitude,
          provider.location.longitude
        );

        if (distance < minDistance) {
          minDistance = distance;
          nearestProvider = provider;
        }
      });

      if (!nearestProvider) return;

      // 5 km rule
      if (minDistance > MAX_DISTANCE_KM) return;

      const requestRef = doc(db, "emergency_requests", alertItem.id);
      const providerRef = doc(db, collectionName, nearestProvider.firestoreId);

      await runTransaction(db, async (transaction) => {
        const requestSnap = await transaction.get(requestRef);
        const providerSnap = await transaction.get(providerRef);

        if (!requestSnap.exists() || !providerSnap.exists()) return;

        const requestData = requestSnap.data();
        const providerData = providerSnap.data();

        if (requestData.status !== "pending") return;
        if (requestData.assignedProviderId) return;
        if (providerData.available !== true) return;

        transaction.update(requestRef, {
          status: "assigned",
          assignedProviderId: providerData.id || nearestProvider.firestoreId,
          assignedProviderFirestoreId: nearestProvider.firestoreId,
          assignedProviderCollection: collectionName,
          assignedProviderName:
            providerData.serviceProviderName || "Unknown Provider",
          assignedProviderPhone: providerData.phone || "N/A",
          assignedDistanceKm: minDistance.toFixed(2),
        });

        transaction.update(providerRef, {
          available: false,
        });
      });
    } catch (error) {
      console.error("Auto assignment error:", error);
    }
  };

  const handleOnTheWay = async (alertItem) => {
    try {
      await updateDoc(doc(db, "emergency_requests", alertItem.id), {
        status: "on_the_way",
      });
    } catch (error) {
      console.error("Error updating to on_the_way:", error);
    }
  };

  const handleResolve = async (alertItem) => {
    try {
      await updateDoc(doc(db, "emergency_requests", alertItem.id), {
        status: "resolved",
      });

      if (
        alertItem.assignedProviderCollection &&
        alertItem.assignedProviderFirestoreId
      ) {
        await updateDoc(
          doc(
            db,
            alertItem.assignedProviderCollection,
            alertItem.assignedProviderFirestoreId
          ),
          { available: true }
        );
      }
    } catch (error) {
      console.error("Error resolving request:", error);
    }
  };

  const getEffectiveStatus = (alertItem) => {
    const distance = parseFloat(alertItem.assignedDistanceKm);

    if (
      alertItem.status === "pending" &&
      (alertItem.assignedProviderId || alertItem.assignedProviderName)
    ) {
      if (!isNaN(distance) && distance <= MAX_DISTANCE_KM) {
        return "assigned";
      }
      return "pending";
    }

    return alertItem.status;
  };

  const inferUrgency = (alertItem) => {
    const savedUrgency = alertItem.urgency || alertItem.Urgency;

    if (savedUrgency) return savedUrgency.toUpperCase();

    const text = `${alertItem.description || ""} ${alertItem.serviceType || ""}`.toLowerCase();

    if (
      text.includes("fire") ||
      text.includes("smoke") ||
      text.includes("burn") ||
      text.includes("blood") ||
      text.includes("bleeding") ||
      text.includes("unconscious") ||
      text.includes("heart") ||
      text.includes("attack")
    ) {
      return "CRITICAL";
    }

    if (
      text.includes("accident") ||
      text.includes("robbery") ||
      text.includes("fight") ||
      text.includes("theft") ||
      text.includes("snatching") ||
      text.includes("injury") ||
      text.includes("kidnap") ||
      text.includes("kidnapping") ||
      text.includes("abduct") ||
      text.includes("abduction")
    ) {
      return "HIGH";
    }

    if (
      text.includes("pain") ||
      text.includes("dizzy") ||
      text.includes("help")
    ) {
      return "MEDIUM";
    }

    return "LOW";
  };

  const getUrgencyColor = (urgency) => {
    if (urgency === "CRITICAL") return "#dc2626";
    if (urgency === "HIGH") return "#ea580c";
    if (urgency === "MEDIUM") return "#ca8a04";
    return "#16a34a";
  };

  const getCardColor = (status) => {
    if (status === "pending") return "#fff1f2";
    if (status === "assigned") return "#fff7ed";
    if (status === "on_the_way") return "#eff6ff";
    if (status === "resolved") return "#f0fdf4";
    return "#f9fafb";
  };

  const getBorderColor = (status) => {
    if (status === "pending") return "#ef4444";
    if (status === "assigned") return "#f97316";
    if (status === "on_the_way") return "#3b82f6";
    if (status === "resolved") return "#22c55e";
    return "#9ca3af";
  };

  const getStatusBadgeColor = (status) => {
    if (status === "pending") return "#ef4444";
    if (status === "assigned") return "#f97316";
    if (status === "on_the_way") return "#3b82f6";
    if (status === "resolved") return "#22c55e";
    return "#6b7280";
  };

  const getServiceEmoji = (serviceType) => {
    const type = (serviceType || "").toLowerCase();
    if (type === "ambulance") return "🚑";
    if (type === "police") return "🚓";
    if (type === "fire" || type === "fire brigade") return "🚒";
    return "🚨";
  };

  const getMapLink = (location) => {
    if (!location || location.latitude == null || location.longitude == null) {
      return null;
    }
    return `https://www.google.com/maps?q=${location.latitude},${location.longitude}`;
  };

  const validAlerts = alerts.filter(
    (alertItem) =>
      alertItem.serviceType &&
      alertItem.user &&
      alertItem.location &&
      alertItem.location.latitude != null &&
      alertItem.location.longitude != null
  );

  const filteredAlerts = validAlerts
    .filter((alertItem) => {
      const effectiveStatus = getEffectiveStatus(alertItem);
      const urgency = inferUrgency(alertItem);

      const statusOk =
        statusFilter === "all" || effectiveStatus === statusFilter;

      const urgencyOk =
        urgencyFilter === "all" || urgency === urgencyFilter;

      return statusOk && urgencyOk;
    })
    .sort((a, b) => {
      const urgencyA = inferUrgency(a);
      const urgencyB = inferUrgency(b);

      return urgencyOrder[urgencyA] - urgencyOrder[urgencyB];
    });

  const totalCount = validAlerts.length;
  const pendingCount = validAlerts.filter(
    (a) => getEffectiveStatus(a) === "pending"
  ).length;
  const assignedCount = validAlerts.filter(
    (a) => getEffectiveStatus(a) === "assigned"
  ).length;
  const onTheWayCount = validAlerts.filter(
    (a) => getEffectiveStatus(a) === "on_the_way"
  ).length;
  const resolvedCount = validAlerts.filter(
    (a) => getEffectiveStatus(a) === "resolved"
  ).length;

  const criticalCount = validAlerts.filter(
    (a) => inferUrgency(a) === "CRITICAL"
  ).length;
  const highCount = validAlerts.filter((a) => inferUrgency(a) === "HIGH").length;

  return (
    <div
      style={{
        padding: "24px",
        fontFamily: "Arial, sans-serif",
        background: "linear-gradient(to bottom, #f8fafc, #eef2ff)",
        minHeight: "100vh",
      }}
    >
      <h1
        style={{
          textAlign: "center",
          marginBottom: "24px",
          fontSize: "42px",
          fontWeight: "800",
        }}
      >
        🚨 Emergency Dashboard
      </h1>

      <div
        style={{
          display: "flex",
          justifyContent: "center",
          gap: "14px",
          flexWrap: "wrap",
          marginBottom: "24px",
        }}
      >
        <SummaryCard label="Total" value={totalCount} color="#111827" />
        <SummaryCard label="Critical" value={criticalCount} color="#dc2626" />
        <SummaryCard label="High" value={highCount} color="#ea580c" />
        <SummaryCard label="Pending" value={pendingCount} color="#ef4444" />
        <SummaryCard label="Assigned" value={assignedCount} color="#f97316" />
        <SummaryCard label="On The Way" value={onTheWayCount} color="#3b82f6" />
        <SummaryCard label="Resolved" value={resolvedCount} color="#22c55e" />
      </div>

      <div style={{ textAlign: "center", marginBottom: "12px" }}>
        <button onClick={() => setStatusFilter("all")} style={filterBtnStyle}>All</button>
        <button onClick={() => setStatusFilter("pending")} style={filterBtnStyle}>Pending</button>
        <button onClick={() => setStatusFilter("assigned")} style={filterBtnStyle}>Assigned</button>
        <button onClick={() => setStatusFilter("on_the_way")} style={filterBtnStyle}>On The Way</button>
        <button onClick={() => setStatusFilter("resolved")} style={filterBtnStyle}>Resolved</button>
      </div>

      <div style={{ textAlign: "center", marginBottom: "28px" }}>
        <button onClick={() => setUrgencyFilter("all")} style={filterBtnStyle}>All Urgency</button>
        <button onClick={() => setUrgencyFilter("CRITICAL")} style={filterBtnStyle}>Critical</button>
        <button onClick={() => setUrgencyFilter("HIGH")} style={filterBtnStyle}>High</button>
        <button onClick={() => setUrgencyFilter("MEDIUM")} style={filterBtnStyle}>Medium</button>
        <button onClick={() => setUrgencyFilter("LOW")} style={filterBtnStyle}>Low</button>
      </div>

      {filteredAlerts.length === 0 ? (
        <p style={{ textAlign: "center", fontSize: "18px", color: "#4b5563" }}>
          No alerts found
        </p>
      ) : (
        <div
          style={{
            display: "flex",
            flexWrap: "wrap",
            gap: "22px",
            justifyContent: "center",
          }}
        >
          {filteredAlerts.map((alertItem) => {
            const effectiveStatus = getEffectiveStatus(alertItem);
            const urgency = inferUrgency(alertItem);
            const assignedDistance = parseFloat(alertItem.assignedDistanceKm);

            const isNearbyAssigned =
              !isNaN(assignedDistance) && assignedDistance <= MAX_DISTANCE_KM;

            const waitingForNearbyProvider = effectiveStatus === "pending";

            return (
              <div
                key={alertItem.id}
                style={{
                  width: "360px",
                  borderRadius: "18px",
                  padding: "20px",
                  backgroundColor: getCardColor(effectiveStatus),
                  border: `2px solid ${getBorderColor(effectiveStatus)}`,
                  boxShadow: "0 8px 20px rgba(0,0,0,0.12)",
                }}
              >
                <div
                  style={{
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "center",
                    gap: "10px",
                    flexWrap: "wrap",
                  }}
                >
                  <h2 style={{ marginTop: 0, marginBottom: "12px" }}>
                    {getServiceEmoji(alertItem.serviceType)} {alertItem.serviceType}
                  </h2>

                  <div style={{ display: "flex", gap: "8px", flexWrap: "wrap" }}>
                    <span
                      style={{
                        backgroundColor: getUrgencyColor(urgency),
                        color: "white",
                        padding: "6px 10px",
                        borderRadius: "999px",
                        fontSize: "12px",
                        fontWeight: "700",
                      }}
                    >
                      {urgency}
                    </span>

                    <span
                      style={{
                        backgroundColor: getStatusBadgeColor(effectiveStatus),
                        color: "white",
                        padding: "6px 10px",
                        borderRadius: "999px",
                        fontSize: "12px",
                        fontWeight: "700",
                        textTransform: "capitalize",
                      }}
                    >
                      {effectiveStatus}
                    </span>
                  </div>
                </div>

                <p><b>ID:</b> {alertItem.id}</p>
                <p><b>User:</b> {alertItem.user}</p>
                <p><b>Description:</b> {alertItem.description || "Not available"}</p>

                <p>
                  <b>Location:</b>{" "}
                  {getMapLink(alertItem.location) ? (
                    <a
                      href={getMapLink(alertItem.location)}
                      target="_blank"
                      rel="noreferrer"
                    >
                      View on Map 📍
                    </a>
                  ) : (
                    "N/A"
                  )}
                </p>

                <p>
                  <b>Coordinates:</b>{" "}
                  {alertItem.location
                    ? `${alertItem.location.latitude}, ${alertItem.location.longitude}`
                    : "N/A"}
                </p>

                <hr
                  style={{
                    margin: "14px 0",
                    border: "none",
                    borderTop: "1px solid #d1d5db",
                  }}
                />

                <p>
                  <b>Provider:</b>{" "}
                  {isNearbyAssigned ? alertItem.assignedProviderName : "Not assigned yet"}
                </p>

                <p>
                  <b>Phone:</b>{" "}
                  {isNearbyAssigned ? alertItem.assignedProviderPhone : "N/A"}
                </p>

                <p>
                  <b>Distance:</b>{" "}
                  {isNearbyAssigned ? `${alertItem.assignedDistanceKm} km` : "N/A"}
                </p>

                {waitingForNearbyProvider && (
                  <p style={{ color: "#ef4444", fontWeight: "700" }}>
                    Waiting for Provider within 5 km
                  </p>
                )}

                <div style={{ marginTop: "16px" }}>
                  {effectiveStatus === "pending" && (
                    <button
                      disabled
                      style={{
                        ...actionBtnStyle,
                        backgroundColor: "#9ca3af",
                        cursor: "not-allowed",
                      }}
                    >
                      Waiting for Assignment
                    </button>
                  )}

                  {effectiveStatus === "assigned" && (
                    <button
                      onClick={() => handleOnTheWay(alertItem)}
                      style={{ ...actionBtnStyle, backgroundColor: "#f97316" }}
                    >
                      On The Way
                    </button>
                  )}

                  {effectiveStatus === "on_the_way" && (
                    <button
                      onClick={() => handleResolve(alertItem)}
                      style={{ ...actionBtnStyle, backgroundColor: "#3b82f6" }}
                    >
                      Resolve
                    </button>
                  )}

                  {effectiveStatus === "resolved" && (
                    <button
                      disabled
                      style={{
                        ...actionBtnStyle,
                        backgroundColor: "#22c55e",
                        cursor: "not-allowed",
                      }}
                    >
                      Completed
                    </button>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

function SummaryCard({ label, value, color }) {
  return (
    <div
      style={{
        minWidth: "120px",
        backgroundColor: "white",
        borderRadius: "14px",
        padding: "14px 18px",
        boxShadow: "0 4px 12px rgba(0,0,0,0.08)",
        textAlign: "center",
        borderTop: `4px solid ${color}`,
      }}
    >
      <div style={{ fontSize: "14px", color: "#6b7280", marginBottom: "6px" }}>
        {label}
      </div>
      <div style={{ fontSize: "26px", fontWeight: "800", color }}>{value}</div>
    </div>
  );
}

const filterBtnStyle = {
  margin: "5px",
  padding: "10px 16px",
  borderRadius: "10px",
  border: "1px solid #cbd5e1",
  cursor: "pointer",
  backgroundColor: "white",
  fontWeight: "600",
};

const actionBtnStyle = {
  padding: "10px 16px",
  color: "white",
  border: "none",
  borderRadius: "10px",
  cursor: "pointer",
  fontWeight: "700",
};

export default App;