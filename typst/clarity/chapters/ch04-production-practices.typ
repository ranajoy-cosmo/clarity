// chapters/ch04-production-practices.typ
#import "../theme.typ": note, tip, warning, danger, chapter-intro

= Practices for Production-Grade Python

#chapter-intro[
  A codebase that works on your machine is a starting point, not an
  achievement. Making it production-grade means it is observable,
  secure, testable, and maintainable by anyone — including yourself
  six months from now. These practices are the difference between
  code you ship and code you trust.
]

== Static Typing

Python is dynamically typed, but that does not mean your code has to
be untyped. Type annotations give you machine-readable documentation,
catch bugs before runtime, and make refactoring much safer.

=== Adding Type Annotations

```python
from collections.abc import Sequence

def top_k(scores: dict[str, float], *, k: int = 5) -> list[str]:
    return sorted(scores, key=scores.__getitem__, reverse=True)[:k]
```

Annotate function signatures first — they give you the most benefit
for the least effort. Add annotations as you touch code, not in one
heroic sweep.

=== Static Analysis with mypy / pyright

A type checker finds errors at analysis time, not at 2 a.m. in
production. Run it in CI so that unannotated or mismatched types
become a build failure, not a surprise.

```toml
# pyproject.toml
[tool.mypy]
strict = true
ignore_missing_imports = true
```

#tip[
  Start with `strict = false` on a legacy codebase and tighten the
  settings over time. Enabling `disallow_untyped_defs` alone catches
  a large class of bugs with minimal friction.
]

== Testing

Tests are the proof that your code does what you think it does. More
importantly, they are the safety net that lets you change code
confidently.

=== The Testing Pyramid

Unit tests are fast and isolated. Integration tests verify that
components work together. End-to-end tests confirm user-visible
behaviour. The pyramid shape — many unit tests, fewer integration,
fewer still end-to-end — is not a rule but a heuristic about cost
and feedback speed.

=== Writing Tests with pytest

```python
import pytest
from mypackage import top_k

def test_top_k_returns_correct_count():
    scores = {"a": 0.9, "b": 0.1, "c": 0.5, "d": 0.8}
    assert len(top_k(scores, k=2)) == 2

def test_top_k_order():
    scores = {"a": 0.9, "b": 0.1, "c": 0.5}
    assert top_k(scores, k=2) == ["a", "c"]

def test_top_k_empty_input():
    assert top_k({}, k=3) == []
```

#tip[
  Name tests as sentences: `test_top_k_returns_correct_count` is a
  specification. When a test fails, the name tells you what broke.
]

=== Fixtures and Test Data

Use fixtures to build objects once and share them. Prefer factories
over hardcoded data so that tests remain readable as requirements
change.

```python
@pytest.fixture
def sample_scores() -> dict[str, float]:
    return {"alpha": 0.9, "beta": 0.4, "gamma": 0.7}
```

=== Coverage as a Signal, Not a Goal

Coverage tells you which lines were executed by your test suite. It
does not tell you whether those tests are meaningful. Aim for high
coverage of business logic; accept lower coverage for boilerplate
and generated code. A 90 % figure with weak assertions is worse than
80 % with strong ones.

#warning[
  Chasing 100 % coverage often leads to tests that assert nothing
  useful — they exist only to satisfy a metric. Trust the number
  less than the quality of the assertions.
]

== Observability

You cannot fix what you cannot see. Observability is the ability to
understand the state of your system from its outputs — without
deploying new code every time something goes wrong.

=== Structured Logging

Plain text log lines are hard to query at scale. Emit logs as
structured records (JSON) so that log aggregation systems can filter
and analyse them efficiently.

```python
import structlog

log = structlog.get_logger()

def process_request(request_id: str, payload: dict) -> None:
    log.info("request.received", request_id=request_id, size=len(payload))
```

Always include a request or trace identifier so you can follow a
single transaction across multiple log entries.

=== Metrics

Counters, gauges, and histograms describe the health of your system
over time. Instrument the things that matter: request rates, error
rates, and latency (the so-called RED metrics — Rate, Errors,
Duration).

=== Distributed Tracing

In a system with more than one service, a single user request fans
out across multiple processes. Distributed tracing records the entire
call graph for a request. When something is slow, you can see exactly
where the time was spent.

#note[
  Logging, metrics, and tracing are complementary, not interchangeable.
  Logs answer "what happened", metrics answer "how often / how fast",
  traces answer "where did time go".
]

== Error Handling and Resilience

Distributed systems fail in partial, unpredictable ways. Robust code
expects failure and degrades gracefully rather than collapsing
entirely.

=== Typed Error Hierarchies

Define application-specific exception types. Catching a broad
`Exception` at the top level is a last resort, not a strategy.

```python
class AppError(Exception):
    """Base class for all application errors."""

class ValidationError(AppError):
    """Raised when input does not meet schema requirements."""

class ExternalServiceError(AppError):
    """Raised when a third-party call fails."""
```

=== Retries, Timeouts, and Circuit Breakers

Every call to an external service should have a timeout. Retries
should back off exponentially and be bounded in count. A circuit
breaker prevents your service from hammering a dependency that is
already down.

#danger[
  Retrying without idempotency checks can corrupt state. Before adding
  a retry, confirm that the operation is safe to repeat.
]

=== Idempotency

Design mutating operations so that calling them multiple times with
the same input produces the same result. This makes retries safe and
simplifies recovery from partial failures.

== Security

Security is not a feature added at the end — it is a habit practised
throughout development.

=== Secrets Management

Secrets (API keys, passwords, tokens) must never appear in source
code. Use environment variables for local development and a secrets
manager (AWS Secrets Manager, HashiCorp Vault, or similar) in
production.

```python
import os

DATABASE_URL = os.environ["DATABASE_URL"]  # fails loudly if missing
```

#danger[
  A secret committed to version control is a secret no longer.
  Even if you delete it in a later commit, it lives in the git
  history. Rotate it immediately and audit for misuse.
]

=== Dependency Vulnerability Scanning

Your dependencies have vulnerabilities. Run `pip-audit` or integrate
a tool like Dependabot or Snyk into your CI pipeline. Treat a
high-severity finding the same way you would treat a failing test.

=== Input Validation

Validate all data that crosses a system boundary — HTTP requests,
file uploads, queue messages. Reject invalid input early, at the
edge, before it reaches business logic.

== CI/CD

CI/CD is the practice of integrating code changes frequently and
deploying them automatically. It shifts quality checks left: the
sooner a problem is detected, the cheaper it is to fix.

=== Continuous Integration

Every push should trigger a pipeline that lints, type-checks,
tests, and builds. Keep the pipeline fast — a slow pipeline is one
that engineers skip.

A typical ordering for a Python project:

+ `ruff check && ruff format --check` — style and lint in seconds
+ `mypy` — type checking
+ `pytest` — test suite
+ `pip-audit` — dependency vulnerabilities
+ Build artefact / Docker image

=== Deployment Strategies

*Blue/green* deployments maintain two identical environments and
switch traffic atomically. *Canary* releases gradually shift a
percentage of traffic to the new version. *Feature flags* decouple
deploy from release entirely — code goes to production but stays
dark until deliberately enabled.

#tip[
  Separate "deploy" from "release". Deploying should be boring and
  automated. Releasing is a business decision.
]

== Configuration Management

Code that reads its configuration from the environment runs
identically in development, CI, and production without modification.
This is the core insight of the twelve-factor app methodology.

=== Environment-Based Configuration

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str
    debug: bool = False
    max_workers: int = 4

    class Config:
        env_file = ".env"

settings = Settings()
```

Validate configuration at startup. A missing or malformed setting
should kill the process immediately with a clear error message —
not silently produce wrong results hours later.

=== Feature Flags

Feature flags let you merge incomplete features to the main branch
and enable them selectively. They reduce long-lived branches, make
rollbacks trivial, and enable gradual rollouts to subsets of users.

== Dependency Management

Your project's dependencies are part of your codebase. Treat them
with the same discipline as your own code.

=== Lock Files

A lock file records the exact versions of every package (direct and
transitive) that were installed when the project last worked. Always
commit your lock file. Without it, `pip install` produces a
different environment on every machine.

```toml
# pyproject.toml — declare what you need
[project]
dependencies = ["httpx>=0.27", "pydantic>=2.0"]
```

Use `uv` or `pip-tools` to generate and maintain the lock file.

=== Automated Updates

Dependencies go stale. Set up automated pull requests for version
bumps (Dependabot, Renovate) and let your test suite decide whether
to merge them. Regular small updates are safer than infrequent large
ones.

== Documentation

Documentation that is written separately from the code it describes
will eventually lie. Prefer documentation that lives as close to
the code as possible.

=== Architecture Decision Records

An ADR records a significant technical decision: the context, the
options considered, and the reasoning behind the choice. It is the
answer to "why does the code look like this?" — a question that no
amount of inline comments can fully address.

Keep ADRs short (one page), dated, and in the repository. They are
never deleted; superseded decisions are marked as such.

=== Runbooks

A runbook describes how to operate a piece of the system: how to
deploy it, how to restart it, what to do when a specific alert
fires. Write runbooks for every alert that wakes someone up at
night.

#tip[
  If you find yourself explaining the same incident response steps
  twice, write a runbook. Future-you, holding a pager at 3 a.m.,
  will be grateful.
]

== Developer Experience

The friction to make a local change and see its effect is a tax on
every decision your team makes. Minimise it.

=== One-Command Setup

A new contributor should be able to clone the repository, run a
single command, and have a working development environment. Makefile
targets, `uv sync`, and Docker Compose are common tools for this.

=== Pre-commit Hooks

Run fast checks (formatting, linting, type-checking) before every
commit rather than waiting for CI. This catches trivial issues
without consuming pipeline minutes.

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.4.0
    hooks:
      - id: ruff
      - id: ruff-format
```

=== Database Migrations

Schema changes must be versioned, automated, and reversible.
Migration tools (Alembic for SQLAlchemy, Django migrations) record
every schema change as a numbered script that can be applied
forward or rolled back. Never modify the database schema by hand in
any environment.

#warning[
  A migration that cannot be rolled back is a liability. Before
  merging, ask: "What is the rollback procedure for this change?"
]
