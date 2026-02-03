# Contributing

## Getting Started

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes
4. Run tests: `npm test`
5. Run linting: `npm run lint`
6. Commit with a descriptive message
7. Push and open a pull request

## Code Standards

- Follow existing code patterns and conventions
- All new endpoints must include audit logging middleware
- Role-based access control must be applied to every protected route
- No sensitive data (patient names, medical details) in log messages
- Write tests for new functionality

## Security

- Never commit `.env` files or credentials
- Report security vulnerabilities privately — do not open public issues
