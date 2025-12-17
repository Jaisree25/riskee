# Claude Code Instructions for Feature 1

## When Starting a Session

1. **Read the current context:**
   - Check [.claude/project-context.md](.claude/project-context.md) for project status
   - Review the current milestone journal: [docs/ver_0_1/Feature_1_PricePrediction/milestones/M1/journal.md](docs/ver_0_1/Feature_1_PricePrediction/milestones/M1/journal.md)

2. **Ask the user:**
   - "What task from M1 would you like to work on today?"
   - "Should I update the journal with today's date?"

3. **Before coding:**
   - Review the relevant section in the milestone plan
   - Check dependencies (what tasks must be done first)
   - Confirm the acceptance criteria

## Coding Standards

### Python
- Use Python 3.11+ features
- Follow PEP 8 (enforced by Ruff)
- Use type hints for all functions
- Write docstrings (Google style)
- Maximum line length: 88 characters
- Use async/await for I/O operations
- Exception handling: specific exceptions, not bare `except`

Example:
```python
async def fetch_market_data(symbol: str, timeout: int = 30) -> dict[str, Any]:
    """Fetch market data for a given symbol.

    Args:
        symbol: Stock symbol (e.g., "NVDA")
        timeout: Request timeout in seconds

    Returns:
        Dictionary containing price, volume, timestamp

    Raises:
        ValueError: If symbol format is invalid
        TimeoutError: If request exceeds timeout
    """
    pass
```

### Docker & Config
- Use environment variables for configuration
- Never hardcode secrets
- Document all environment variables in .env.example
- Use health checks in docker-compose
- Set resource limits (CPU, memory)

### Testing
- Write tests before or alongside code (TDD encouraged)
- Test file naming: `test_*.py`
- Use pytest fixtures for setup/teardown
- Aim for >80% code coverage
- Test happy path, edge cases, and error handling

### Documentation
- Update journal.md daily
- Update milestone task checkboxes as you complete tasks
- Document all configuration options
- Keep README.md current
- Add inline comments for complex logic only

## File Structure Conventions

### Service Structure
```
services/
└── service_name/
    ├── __init__.py
    ├── main.py              # Entry point
    ├── config.py            # Configuration
    ├── models.py            # Pydantic models
    ├── handlers/            # Business logic
    │   └── __init__.py
    ├── utils/               # Utilities
    │   └── __init__.py
    ├── tests/               # Tests
    │   ├── __init__.py
    │   └── test_main.py
    └── README.md            # Service documentation
```

### Test Structure
```
tests/
├── unit/                    # Unit tests
├── integration/             # Integration tests
├── e2e/                     # End-to-end tests
└── conftest.py              # Pytest fixtures
```

## Git Workflow

### Branch Naming
- `feature/m1-docker-setup`
- `feature/m2-ingestion-agent`
- `bugfix/redis-connection-timeout`
- `docs/update-m1-journal`

### Commit Messages
```
feat(m1): add TimescaleDB service to docker-compose

- Configure TimescaleDB container with persistent volume
- Add health check and initialization scripts
- Document connection parameters in .env.example

Refs: M1-T2.2
```

Format: `<type>(<scope>): <subject>`

Types: feat, fix, docs, style, refactor, test, chore

### Pull Request Checklist
- [ ] Tests passing locally
- [ ] Code formatted with Ruff
- [ ] Type checking passing (if using mypy)
- [ ] Documentation updated
- [ ] Journal.md updated
- [ ] Milestone tasks checked off
- [ ] No secrets committed
- [ ] PR description references milestone task

## Task Workflow

1. **Pick a task** from the milestone document
2. **Mark as in progress** in journal.md
3. **Create a branch** (e.g., `feature/m1-docker-setup`)
4. **Implement the task:**
   - Write tests first (TDD) or alongside code
   - Follow coding standards
   - Add documentation
5. **Test locally:**
   - Run unit tests
   - Run integration tests if applicable
   - Test manually
6. **Update documentation:**
   - Check off task in milestone document
   - Update journal.md with progress
   - Update any relevant README files
7. **Create PR:**
   - Reference milestone task
   - Request 2 reviewers
8. **Merge and deploy:**
   - After approval, merge to develop
   - Update project-context.md if needed

## Journal Updates

Update [M1/journal.md](docs/ver_0_1/Feature_1_PricePrediction/milestones/M1/journal.md) daily:

```markdown
### 📅 Day 1: [Date: 2025-12-16]

**Team Members Active:**
- [x] DevOps Lead
- [x] Backend Dev

**Tasks Started:**
- [x] T1.1 - Create GitHub repository structure
- [x] T2.1 - Create base docker-compose.yml

**Tasks Completed:**
- [x] T1.1 - Create GitHub repository structure

**Blockers:**
- None

**Notes:**
- Repository created: https://github.com/org/riskee
- Set up branch protection rules
- Team has access

**Next Steps:**
- Complete docker-compose.yml tomorrow
- Start TimescaleDB configuration
```

## Common Pitfalls to Avoid

1. **Don't skip tests** - Write tests as you go
2. **Don't hardcode values** - Use environment variables
3. **Don't commit secrets** - Use .env (gitignored)
4. **Don't skip documentation** - Update journal daily
5. **Don't work on blocked tasks** - Check dependencies first
6. **Don't forget error handling** - Handle exceptions properly
7. **Don't skip code review** - Always get 2 approvals
8. **Don't forget GPU drivers** - Verify before starting M4/M5

## M1-Specific Guidelines

### Docker Compose
- Start with minimal services (TimescaleDB, Redis)
- Add one service at a time
- Test each service before adding next
- Use health checks for all services
- Document port mappings

### Database Setup
- Use Alembic for migrations
- Version all schema changes
- Test rollback capability
- Document all tables and indexes
- Use TimescaleDB-specific features (hypertables)

### NATS Setup
- Configure JetStream persistence
- Define streams and subjects clearly
- Test pub/sub before proceeding
- Document message schemas (JSON Schema)
- Monitor message lag

### Monitoring
- Start with basic health checks
- Add metrics incrementally
- Create dashboards as you go
- Test alerts before relying on them
- Document alert thresholds

## Need Help?

1. Check the architecture document
2. Check the milestone plan
3. Check the journal for past decisions
4. Search the codebase for similar patterns
5. Ask the team in Slack
6. Update the journal with blockers

## End of Session

Before ending your session:
1. Update journal.md with today's progress
2. Check off completed tasks in milestone document
3. Commit and push your work
4. Create PR if task is complete
5. Update project-context.md if milestone status changed
6. Note any blockers for next session

---

**These instructions are living documentation. Update them as the project evolves.**
