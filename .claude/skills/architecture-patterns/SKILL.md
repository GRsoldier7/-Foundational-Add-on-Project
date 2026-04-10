---
name: architecture-patterns
description: Implement proven backend architecture patterns including Clean Architecture, Hexagonal Architecture, and Domain-Driven Design. Use this skill when designing clean architecture for a new microservice, when refactoring a monolith to use bounded contexts, when implementing hexagonal or onion architecture patterns, or when debugging dependency cycles between application layers.
---

# Architecture Patterns

**Given:** a service boundary or module to architect.
**Produces:** layered structure with clear dependency rules, interface definitions, and test boundaries.

## Core Concepts

| Pattern | Layers / Components | Key Rule |
|---------|-------------------|----------|
| **Clean Architecture** | Entities → Use Cases → Interface Adapters → Frameworks & Drivers | Dependencies point inward only; inner layers know nothing about outer layers |
| **Hexagonal (Ports & Adapters)** | Domain Core + Ports (abstract interfaces) + Adapters (concrete implementations) | Swap implementations without touching core; in-memory adapters for tests |
| **Domain-Driven Design** | Bounded Contexts, Context Mapping, Ubiquitous Language | Strategic patterns define boundaries; tactical patterns enforce consistency |

### DDD Tactical Patterns

| Pattern | Purpose | Rule |
|---------|---------|------|
| **Entity** | Object with stable identity that changes over time | Identity-based equality |
| **Value Object** | Immutable, attribute-based identity (Email, Money) | Validate invariants in constructor |
| **Aggregate** | Consistency boundary; only root is accessible externally | One transaction per aggregate |
| **Repository** | Persist/reconstitute aggregates; abstract over storage | Interface in domain, impl in adapters |
| **Domain Event** | Capture things that happened; cross-aggregate coordination | Produced by aggregates, consumed asynchronously |

---

## Directory Structure

```
app/
├── domain/           # Entities, value objects, interfaces
│   ├── entities/
│   ├── value_objects/
│   └── interfaces/   # Abstract ports (no implementations)
├── use_cases/        # Application business rules
├── adapters/         # Concrete implementations
│   ├── repositories/
│   ├── controllers/
│   └── gateways/
└── infrastructure/   # Framework wiring, config, DI container
```

**Import rule:** every `import` in `domain/` and `use_cases/` must point only toward `domain/`; nothing in those layers may import from `adapters/` or `infrastructure/`.

---

## Testing Pattern

The hallmark of correct architecture: every use case runs with in-memory adapters, no database, no Docker.

```python
# Implement IRepository with a Dict store for tests
class InMemoryUserRepository(IUserRepository):
    def __init__(self): self._store = {}
    async def save(self, user): self._store[user.id] = user; return user
    async def find_by_email(self, email): return next((u for u in self._store.values() if u.email == email), None)

# Use case test — pure, fast, no infrastructure
async def test_create_user():
    repo = InMemoryUserRepository()
    result = await CreateUserUseCase(user_repository=repo).execute(CreateUserRequest(email="a@b.com", name="A"))
    assert result.success
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Use case tests need a running DB | Business logic leaked into infra | Move DB calls behind IRepository; inject in-memory in tests |
| Circular imports between layers | Use case imports concrete adapter | use_cases/ imports only from domain/ (entities + interfaces) |
| ORM decorators on domain entities | Entity is no longer pure | Separate ORM model in adapters/; map to/from entity in repository |
| All logic in controllers | Missing use case layer | Controller does 3 things: parse request, call use case, map response |
| Value object errors surface late | No constructor validation | Validate invariants in `__post_init__` / constructor |
| Context bleed across bounded contexts | Direct cross-context entity imports | Anti-Corruption Layer + lightweight value object (e.g., CustomerId) |

---

## Related Skills

- `microservices-patterns` — Apply these patterns when decomposing a monolith
- `cqrs-implementation` — Clean Architecture as foundation for CQRS
- `saga-orchestration` — Sagas require well-defined aggregate boundaries (DDD)
- `event-store-design` — Domain events from aggregates feed into event stores
