# Smart Customer Service and Support System

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Laravel](https://img.shields.io/badge/Laravel-11.x-red)
![FastAPI](https://img.shields.io/badge/FastAPI-0.115-green)
![Docker](https://img.shields.io/badge/Docker-Compose-blue)

An AI-powered customer service platform built with **Laravel** and **FastAPI**, featuring intelligent chatbots, sentiment analysis, ticket routing, and a knowledge base, all containerized with Docker for seamless deployment.

## Overview
This project delivers an automated, intelligent customer service system to streamline support operations and enhance user experience. It combines a robust **Laravel** backend for ticketing and user management with **FastAPI** for AI-driven features like chatbots and sentiment analysis.

## Objectives
- **Increase Efficiency**: Automate responses and ticket assignments to reduce manual effort.
- **Improve Customer Experience**: Provide fast, accurate replies, prioritizing urgent issues.
- **Enable Data-Driven Decisions**: Offer real-time analytics via dashboards.
- **Support Flexible Integration**: Handle multi-channel messages through Webhooks.

## Technology Stack
- **Backend (Laravel)**: User management, ticketing system, dashboard, and Webhook receiver with Redis-based async processing.
- **AI Services (FastAPI + Python)**:
  - Chatbot: NLP-driven intent recognition (scikit-learn, upgradable to BERT/GPT).
  - Sentiment Analysis: Detects positive, negative, or neutral tones.
  - Intelligent Ticket Dispatch: Auto-categorizes and assigns tickets.
  - Knowledge Base: Retrieves FAQs from JSON.
  - Modular design with unified error handling.
- **Database**: MySQL
- **Message Queue**: Redis
- **Containerization**: Docker & Docker Compose
- **Future Monitoring**: Prometheus + Grafana (planned).

## Architecture Diagram
```mermaid
graph TD
    A["User"] --> B["Web/App"]
    B --> C["Webhook Receiver (Laravel)"]
    C --> D["AI Processing Job (Laravel Queue/Redis)"]
    D --> E["Chatbot API (FastAPI)"]
    E --> F["AI Service Layer (NLP, Sentiment, etc.)"]
    F --> G["Knowledge Base (JSON/DB/Volume)"]
    F --> H["Persistent Models (Volume)"]
    E --> I["Ticket System (Laravel)"]
    I --> J["Customer Service Agent"]
    J --> K["Dashboard (Laravel)"]
    L["Observability (Monitoring: Prometheus, Grafana)"] <-- E
```

## Quick Start
1. Clone the repository:
   ```bash
   git clone https://github.com/BpsEason/smart-customer-support-system.git
   cd smart-customer-support-system
   ```
2. Copy and configure `.env` files:
   ```bash
   cp laravel-backend/.env.example laravel-backend/.env
   cp fastapi-ai-service/.env.example fastapi-ai-service/.env
   ```
   Update database credentials and `FASTAPI_AI_SERVICE_URL` in `laravel-backend/.env`.
3. Start Docker containers:
   ```bash
   docker compose up -d --build
   ```
4. Set up Laravel:
   ```bash
   docker compose exec php-fpm bash
   composer install
   php artisan key:generate
   php artisan migrate --seed
   exit
   ```
5. Access the application:
   - Laravel: `http://localhost`
   - FastAPI Docs: `http://localhost:8001/docs`

## Key Features

### Laravel Backend
- **User Management**: Register, authenticate, and manage roles (admin, agent, customer).
- **Ticketing System**: Create, reply to, and track tickets with status updates.
- **Dashboard**: Real-time stats on tickets, agent performance, and satisfaction.
- **Webhook Receiver**: Securely ingests external messages (recommend IP whitelisting).
- **Async Processing**: Uses Laravel Queue (Redis) for efficient AI task handling.

### FastAPI AI Services
- **Chatbot**: Understands user queries and provides automated responses.
- **Sentiment Analysis**: Flags high-priority issues based on emotional tone.
- **Ticket Dispatch**: Routes tickets to the best-suited agents or departments.
- **Knowledge Base**: Suggests relevant FAQs from a JSON-based repository.
- **Modular & Robust**: Decoupled AI logic with standardized error handling.

## Detailed Setup
### Prerequisites
- Docker & Docker Compose
- Git

### Environment Configuration
Edit `.env` files in `laravel-backend` and `fastapi-ai-service` to set:
- Database credentials (`DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`).
- FastAPI URL (`FASTAPI_AI_SERVICE_URL=http://fastapi-ai:8001`).
- Optional AI service keys (e.g., `OPENAI_API_KEY`).

### Running Tests
```bash
# Laravel Tests
docker compose exec php-fpm php artisan test

# FastAPI Tests
docker compose exec fastapi-ai pytest
# Specific test
docker compose exec fastapi-ai pytest tests/test_chatbot_service.py
```

## Future Enhancements
- **Observability**: Add OpenTelemetry, Prometheus, and Grafana for monitoring.
- **Knowledge Base**: Migrate to a database for dynamic editing and support RAG with vector databases.
- **AI Models**: Implement versioning (MLflow) and automated retraining.
- **Scalability**: Use Kubernetes for orchestration and Traefik for load balancing.
- **Testing**: Expand unit tests and set up CI/CD with GitHub Actions.

## Contributing
We welcome contributions! Please:
1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/your-feature`).
3. Commit changes (`git commit -m "Add your feature"`).
4. Push to the branch (`git push origin feature/your-feature`).
5. Open a Pull Request.

See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## License
MIT License
