# Mental Health Tribunal Liaison Platform

A secure platform for coordinating communication and case management between **police services**, **mental health tribunals**, and **mental health professionals** under the Mental Health Act.

## Purpose

This application streamlines the process of:

- **Case referrals** between police and mental health professionals
- **Tribunal scheduling and documentation** management
- **Secure communication** between all parties involved in mental health assessments
- **Patient record tracking** with strict access controls and audit logging
- **Statutory compliance** reporting and workflow enforcement

## Key Stakeholders

| Role | Description |
|------|-------------|
| **Police Officers** | Submit referrals, request assessments, provide incident reports |
| **Mental Health Professionals** | Conduct assessments, submit clinical reports, recommend actions |
| **Physicians** | Provide medical assessments, submit clinical opinions, update referral status |
| **Tribunal Panel Members** | Review cases, schedule hearings, issue decisions |
| **Requesting Party** | Initiate tribunal applications, submit referrals, provide supporting evidence |
| **Respondent** | View case details, access hearing information, submit responses |
| **Administrators** | Manage users, configure workflows, generate compliance reports |

## Tech Stack

- **Runtime:** Node.js
- **Framework:** Express.js
- **Database:** PostgreSQL
- **Authentication:** JWT with role-based access control (RBAC)
- **API:** RESTful

## Getting Started

### Prerequisites

- Node.js >= 18.x
- PostgreSQL >= 15.x
- npm >= 9.x

### Installation

```bash
git clone https://github.com/<your-username>/mental-health-tribunal-app.git
cd mental-health-tribunal-app
npm install
cp .env.example .env   # configure your environment variables
npm run db:migrate
npm run dev
```

### Running Tests

```bash
npm test
```

## Project Structure

```
src/
├── api/            # API versioning entry points
├── config/         # App configuration and environment handling
├── middleware/      # Auth, validation, audit logging middleware
├── models/         # Database models and schemas
├── routes/         # Route definitions grouped by domain
├── services/       # Business logic layer
└── utils/          # Shared helpers and constants
tests/              # Unit and integration tests
docs/               # Architecture and compliance documentation
.github/            # CI/CD workflows and issue templates
```

## Security & Compliance

This application handles sensitive personal and medical data. It is designed with:

- **Role-based access control** — users only see data relevant to their role
- **Full audit logging** — every data access and mutation is recorded
- **Encryption at rest and in transit** — TLS and database-level encryption
- **Data retention policies** — configurable per jurisdiction
- **GDPR / Data Protection Act compliance** considerations

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
