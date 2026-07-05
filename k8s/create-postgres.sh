#!/bin/bash

cat > postgres-auth.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-auth
  namespace: togglemaster
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres-auth
  template:
    metadata:
      labels:
        app: postgres-auth
    spec:
      containers:
      - name: postgres
        image: postgres:16
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_USER
          value: admin
        - name: POSTGRES_PASSWORD
          value: admin123
        - name: POSTGRES_DB
          value: auth_db
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-auth
  namespace: togglemaster
spec:
  selector:
    app: postgres-auth
  ports:
  - port: 5432
    targetPort: 5432
EOF

cat > postgres-main.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-main
  namespace: togglemaster
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres-main
  template:
    metadata:
      labels:
        app: postgres-main
    spec:
      containers:
      - name: postgres
        image: postgres:16
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_USER
          value: admin
        - name: POSTGRES_PASSWORD
          value: admin123
        - name: POSTGRES_DB
          value: flags_db
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-main
  namespace: togglemaster
spec:
  selector:
    app: postgres-main
  ports:
  - port: 5432
    targetPort: 5432
EOF

echo "PostgreSQL criado."
