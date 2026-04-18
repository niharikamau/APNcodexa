CRISIS RESPONSE SYSTEM - FIRESTORE STRUCTURE

1. ambulances
- id
- driverName
- phone
- latitude
- longitude
- available
- type

2. police_units
- id
- stationName
- officerName
- phone
- latitude
- longitude
- available

3. fire_units
- id
- stationName
- teamLead
- phone
- latitude
- longitude
- available

4. emergency_requests
- id
- userId
- serviceType
- latitude
- longitude
- status
- assignedUnitId

5. users
- userId
- name
- phone
