
# 💬 Realtime Chat Platform

[![CI/CD Pipeline](https://github.com/Mouad-La/realtime-chat/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/Mouad-La/realtime-chat/actions/workflows/ci-cd.yml)
![React](https://img.shields.io/badge/React-19-149ECA?logo=react&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-20-339933?logo=nodedotjs&logoColor=white)
![Socket.IO](https://img.shields.io/badge/Socket.IO-4-010101?logo=socketdotio&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)

A full-stack **real-time group chat application** built to explore event-driven communication, persistent messaging, Redis Pub/Sub, containerization, CI/CD, and application observability.

Users can open the chat in multiple browser tabs, exchange messages instantly, see typing and connection indicators, and recover recent conversation history after reconnecting. The backend stores messages in PostgreSQL, distributes live events via Redis, and exposes metrics for Prometheus and Grafana.

> **Project status:** Functional demo / engineering portfolio project. The repository includes a Docker Compose environment and a CI workflow, but it is **not yet a production-hardened or fully deployed Kubernetes application**. See [Current limitations](#current-limitations--production-considerations).

## ✨ Features

- **Live messaging:** Bidirectional communication through Socket.IO.
- **Persistent chat history:** PostgreSQL stores messages; the latest **100 messages** are loaded on connection.
- **Redis Pub/Sub:** New socket messages are published on `chat:messages` and rebroadcast to connected clients.
- **Typing indicators:** See when other users are typing.
- **Join/leave notifications:** Lightweight system events when users connect or disconnect.
- **Connection feedback:** The React interface displays its current connection status.
- **Automatic usernames:** Each browser session receives a temporary name such as `User_123` (no account required).
- **REST endpoints:** Health checks, API ping, message history, and message creation.
- **Monitoring:** Custom HTTP, WebSocket, and messaging metrics in Prometheus, with Grafana available for dashboards.
- **Dockerized stack:** Frontend, backend, PostgreSQL, Redis, Prometheus, and Grafana run as Compose services.
- **CI/CD workflow:** GitHub Actions runs backend smoke tests and builds/pushes images to Docker Hub when configured.

## 🛠️ Tech stack

| Layer | Technologies | Purpose |
| --- | --- | --- |
| Frontend | React 19, Vite 8, Socket.IO Client | Chat UI and live updates |
| Backend | Node.js, Fastify 5, Socket.IO | REST API and bidirectional messaging |
| Data | PostgreSQL 16, `pg` | Durable message storage |
| Messaging | Redis 7, `ioredis` | Publish/subscribe fanout |
| Metrics | `prom-client`, Prometheus | Runtime and application telemetry |
| Dashboards | Grafana | Explore and visualize metrics |
| Containers | Docker, Docker Compose, Nginx | Packaging and local orchestration |
| CI/CD | GitHub Actions, Docker Buildx, Docker Hub | Testing and container image publishing |

## 🏗️ Architecture

```mermaid
flowchart LR
    C["React chat client<br/>(served by Nginx)"]
    A["Fastify + Socket.IO<br/>Node.js backend"]
    DB[("PostgreSQL<br/>message history")]
    R[("Redis<br/>Pub/Sub")]
    P["Prometheus"]
    G["Grafana"]

    C <-->|"Socket.IO / REST"| A
    A <-->|"INSERT / SELECT"| DB
    A <-->|"publish / subscribe"| R
    P -->|"scrapes /metrics"| A
    G -->|"queries"| P
```

**Live message flow:**

1. A browser emits a Socket.IO `message` event with `{ sender, text }`.
2. The backend validates the payload and inserts the message into PostgreSQL.
3. The backend publishes the saved message to Redis channel `chat:messages`.
4. The Redis subscriber forwards it to Socket.IO, which broadcasts it to connected browsers.
5. On a new connection, the backend reads the most recent 100 messages from PostgreSQL and emits a `history` event.

**Note:** In the current implementation, messages created through the REST `POST /api/v1/messages` endpoint are saved but **not broadcast** to WebSocket clients. Live broadcasting uses the Socket.IO path.

## 📂 Repository structure

```text
realtime-chat/
├── .github/
│   └── workflows/
│       └── ci-cd.yml               # Tests, Docker images, simulated deploy job
├── backend/
│   ├── src/
│   │   ├── config/
│   │   │   ├── database.js         # PostgreSQL connection pool
│   │   │   ├── redis.js            # Redis publisher and subscriber
│   │   │   └── index.js            # Runtime configuration
│   │   ├── db/migrate.js           # Message table migrations
│   │   ├── middleware/
│   │   │   └── metricsMiddleware.js
│   │   ├── routes/messages.js      # REST message endpoints
│   │   ├── services/
│   │   │   ├── messagesDb.js        # PostgreSQL queries
│   │   │   ├── metrics.js           # Prometheus counters, gauges, histograms
│   │   │   ├── pubsub.js            # Redis message channel
│   │   │   └── socket.js            # Socket.IO events
│   │   ├── app.js                  # Fastify app and API routes
│   │   ├── app.test.js             # Smoke tests
│   │   └── index.js                # Backend entry point
│   ├── Dockerfile
│   └── package.json
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── MessageInput.jsx
│   │   │   └── MessageList.jsx
│   │   ├── hooks/useSocket.js
│   │   ├── pages/ChatPage.jsx
│   │   ├── services/socket.js
│   │   ├── App.jsx
│   │   └── main.jsx
│   ├── Dockerfile
│   ├── nginx.conf                  # Currently serves static assets only
│   └── package.json
├── infra/
│   ├── prometheus/prometheus.yml   # Scrape configuration
│   └── grafana/provisioning/       # Prometheus datasource/dashboard provisioning
├── docker-compose.yml
└── README.md
```

## 🚀 Getting started

### Prerequisites

- [Git](https://git-scm.com/)
- [Docker](https://www.docker.com/) and Docker Compose v2
- For running the code outside containers: **Node.js 20+** and npm

### Option 1 — Docker Compose (recommended for a local demo)

**1. Clone the repository.**

```bash
git clone https://github.com/Mouad-La/realtime-chat.git
cd realtime-chat
```

**2. Configure the frontend's Socket.IO URL.**

The current `docker-compose.yml` builds the frontend with `VITE_API_URL` set to an empty string, so the browser tries to connect to Socket.IO on the Nginx origin. However, the committed `frontend/nginx.conf` does **not** proxy `/socket.io/` to the backend.

For a **local machine only**, create a file named `docker-compose.override.yml` in the repository root:

```yaml
services:
  frontend:
    build:
      args:
        VITE_API_URL: "http://localhost:4000"
  backend:
    environment:
      FRONTEND_URL: "http://localhost"
```

This makes the frontend connect directly to the backend's published port (`4000`) and sets the allowed Socket.IO frontend origin. For remote deployments, configure a real hostname and HTTPS/WSS, or add a reverse proxy for `/socket.io/` instead of using `localhost`.

**3. Build and start the services.**

```bash
docker compose up --build -d
docker compose ps
```

**4. Open the application.**

| Service | Local address |
| --- | --- |
| Chat application | <http://localhost> |
| Backend health | <http://localhost:4000/health> |
| REST API ping | <http://localhost:4000/api/v1/ping> |
| Backend metrics | <http://localhost:4000/metrics> |
| Prometheus | <http://localhost:9090> |
| Grafana | <http://localhost:3000> |

Grafana's **demo-only** credentials in the current Compose file are `admin` / `admin123`.

Try opening the chat in two browser tabs and sending a message. Both tabs should receive the message; reloading should restore recent history.

**5. Inspect logs or shut down.**

```bash
docker compose logs -f backend
docker compose down
```

To also delete all named volumes (including **stored messages**), run `docker compose down -v` **only if you intend to erase the data**.

### Option 2 — Local Node.js development

Start just the data services:

```bash
docker compose up -d postgres redis
```

In the `backend/` directory, install dependencies and create a `.env` file:

```dotenv
NODE_ENV=development
HOST=0.0.0.0
PORT=4000
DATABASE_URL=postgresql://chatuser:chatpassword@localhost:5432/chatdb
REDIS_URL=redis://localhost:6379
FRONTEND_URL=http://localhost:5173
```

Then run:

```bash
cd backend
npm ci
npm run dev
```

The backend runs database migrations on startup. In a **second terminal**, create `frontend/.env.local`:

```dotenv
VITE_API_URL=http://localhost:4000
```

Start the frontend:

```bash
cd frontend
npm ci
npm run dev
```

Open the URL printed by Vite (normally <http://localhost:5173>).

> **Security note:** The database, Redis, and Grafana passwords in the Compose configuration are for local experimentation only. Never expose these defaults or the database/cache ports to an untrusted network.

## 🔌 API and Socket.IO reference

### HTTP endpoints

| Method | Path | Description |
| --- | --- | --- |
| `GET` | `/health` | Status, uptime, timestamp, environment |
| `GET` | `/metrics` | Prometheus metrics in exposition format |
| `GET` | `/api/v1/ping` | API availability check |
| `GET` | `/api/v1/messages` | Latest 100 messages in chronological order |
| `POST` | `/api/v1/messages` | Store a message (does not emit a socket event) |

**Example: read message history**

```bash
curl http://localhost:4000/api/v1/messages
```

**Example: create a message via HTTP**

```bash
curl -X POST http://localhost:4000/api/v1/messages \
  -H "Content-Type: application/json" \
  -d '{"sender":"Alice","text":"Hello from the REST API!"}'
```

Message creation requires a nonempty `sender` (max 50 characters) and `text` (max 2,000 characters).

### Socket.IO events

| Direction | Event | Payload or meaning |
| --- | --- | --- |
| Client → server | `message` | `{ "sender": "Alice", "text": "Hello" }` |
| Client → server | `typing` | `{ "sender": "Alice" }` |
| Server → client | `history` | Recent saved messages array |
| Server → client | `message` | New saved message (`id`, `sender`, `text`, `timestamp`) |
| Server → clients | `typing` | `{ "sender": "Alice" }` |
| Server → clients | `system` | Join/leave notification with text and timestamp |
| Server → client | `error` | Validation or send failure description |

There is currently one **shared/global chat**, not separate rooms or direct messages. No authentication or authorization is implemented.

## 📊 Observability

Prometheus scrapes the backend's `/metrics` endpoint every **10 seconds** and its own metrics every **15 seconds**, according to [`infra/prometheus/prometheus.yml`](infra/prometheus/prometheus.yml).

The backend uses `prom-client` to expose Node.js/process metrics and several application-specific metrics:

| Metric | Type | Description |
| --- | --- | --- |
| `http_requests_total` | Counter | HTTP request count by method, route, and status |
| `http_request_duration_seconds` | Histogram | Request latency distribution |
| `ws_connections_active` | Gauge | Currently connected Socket.IO clients |
| `chat_messages_total` | Counter | Messages accepted through Socket.IO or REST |
| `chat_message_duration_seconds` | Histogram | Socket message processing latency |

Example PromQL queries:

```promql
# Number of connected chat clients
ws_connections_active

# Messages per second over the last 5 minutes
rate(chat_messages_total[5m])

# 95th percentile HTTP request duration
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))
```

Grafana is available at <http://localhost:3000>. Its Prometheus datasource is provisioned to `http://prometheus:9090`. You can create dashboards using the metrics above.

## 🧪 Tests and CI/CD

Run the available backend smoke tests:

```bash
cd backend
npm ci
npm test
```

The test script exercises the health endpoint, API ping, and validation for invalid message submissions. These are **basic smoke tests**, not a comprehensive integration or load-test suite.

The [GitHub Actions workflow](.github/workflows/ci-cd.yml) runs on pushes and pull requests to `main`:

1. **Test backend:** Install npm dependencies and execute `npm test`.
2. **Build and publish images:** On pushes to `main`, build frontend/backend images and push `latest` and short-commit-SHA tags to Docker Hub (requires repository secrets `DOCKER_USERNAME` and `DOCKER_PASSWORD`).
3. **Deploy job:** Currently only prints a simulated Kubernetes deployment message; it does **not** apply Kubernetes manifests or update a cluster.

> The backend's `lint` script is a placeholder, and its smoke tests use `console.assert`. A more rigorous test runner with assertions that fail the process on mismatches is recommended.

## 🗄️ Data storage

On backend startup, a lightweight migration creates the `messages` table if needed:

```sql
CREATE TABLE IF NOT EXISTS messages (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender     VARCHAR(50) NOT NULL,
  text       TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

The migration also creates a descending timestamp index for efficient retrieval of recent messages. Docker volumes preserve PostgreSQL and Redis data across ordinary Compose restarts.

## ⚠️ Current limitations & production considerations

This repository demonstrates the core real-time messaging and DevOps pipeline, but several improvements are needed before treating it as a production system:

- **Frontend routing:** The committed Nginx configuration serves static files but does not proxy Socket.IO traffic. Use the local Compose override above, or implement an appropriate `/socket.io/` reverse proxy.
- **Security:** No sign-up/login, user authorization, per-user identity guarantees, message rate limits, or abuse controls. Session names are randomly generated and may collide.
- **Secrets and networking:** Compose includes plaintext example passwords and exposes PostgreSQL/Redis ports on the host. Move secrets out of the Compose file and restrict network access before deployment.
- **TLS and CORS:** Configure HTTPS/WSS, trusted frontend origins, and a reverse proxy or gateway for public access.
- **Delivery semantics:** Redis Pub/Sub distributes live events but does not persist events for offline delivery. PostgreSQL provides message history; there are no delivery acknowledgements/read receipts.
- **API/event consistency:** `POST /api/v1/messages` does not publish to Redis or immediately notify connected browsers.
- **Operations:** Expand automated tests, build health checks and CI coverage, implement graceful cleanup for database and Redis clients, and test recovery under failures.
- **Kubernetes:** The CI deployment step is a simulation rather than an actual rollout. No deployed environment is claimed here.

## 🗺️ Suggested roadmap

- [ ] Add authenticated users and stable identities
- [ ] Support private conversations and multiple chat rooms
- [ ] Broadcast REST-created messages consistently
- [ ] Put the frontend and backend behind a single HTTPS reverse proxy
- [ ] Introduce rate limiting and message validation across all entry points
- [ ] Add backend unit/integration tests and frontend tests
- [ ] Implement delivery receipts, pagination, and presence tracking
- [ ] Build versioned Grafana dashboards and add alerting rules
- [ ] Implement a real Kubernetes deployment and infrastructure-as-code pipeline

## 👤 Author

Created by **[Mouad-La](https://github.com/Mouad-La)**.

Project repository: **[Mouad-La/realtime-chat](https://github.com/Mouad-La/realtime-chat)**
