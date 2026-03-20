.DEFAULT_GOAL := help

UV      := uv
SRC     := src/
TESTS   := tests/
SCRIPTS := scripts/

TYPST_MAIN := typst/main.typ
TYPST_OUT  := typst/output/knowledge-base.pdf

# ── Help ──────────────────────────────────────────────────────────────────────

.PHONY: help
help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ── Environment ───────────────────────────────────────────────────────────────

.PHONY: install
install: ## Install all dependencies (dev + extras)
	$(UV) sync --all-extras --dev

# ── Code Quality ──────────────────────────────────────────────────────────────

.PHONY: lint
lint: ## Check code style and lint rules (ruff)
	$(UV) run ruff check $(SRC) $(TESTS) $(SCRIPTS)
	$(UV) run ruff format --check $(SRC) $(TESTS) $(SCRIPTS)

.PHONY: format
format: ## Auto-fix lint issues and reformat code (ruff)
	$(UV) run ruff check --fix $(SRC) $(TESTS) $(SCRIPTS)
	$(UV) run ruff format $(SRC) $(TESTS) $(SCRIPTS)

.PHONY: typecheck
typecheck: ## Run static type checking (mypy)
	$(UV) run mypy $(SRC)

# ── Tests ─────────────────────────────────────────────────────────────────────

.PHONY: test
test: ## Run test suite with coverage (parallel)
	$(UV) run pytest -n auto --cov=src/clarity --cov-report=term-missing --cov-fail-under=90

.PHONY: test-verbose
test-verbose: ## Run tests with full output (no parallel)
	$(UV) run pytest -v --cov=src/clarity --cov-report=term-missing

# ── Notebooks ─────────────────────────────────────────────────────────────────

.PHONY: notebooks
notebooks: ## Execute all notebooks and validate output
	$(UV) run python $(SCRIPTS)execute_notebooks.py

# ── Documentation ─────────────────────────────────────────────────────────────

.PHONY: docs
docs: ## Serve documentation site locally with live reload
	$(UV) run mkdocs serve

.PHONY: docs-build
docs-build: ## Build documentation site (strict — warnings = errors)
	$(UV) run mkdocs build --strict

# ── Typst ─────────────────────────────────────────────────────────────────────

.PHONY: pdf
pdf: ## Compile Typst source to PDF
	@mkdir -p typst/output
	typst compile $(TYPST_MAIN) $(TYPST_OUT)
	@echo "PDF written to $(TYPST_OUT)"

# ── Aggregate ─────────────────────────────────────────────────────────────────

.PHONY: check
check: lint typecheck test ## Full local CI pass (lint + typecheck + test)

.PHONY: check-all
check-all: lint typecheck test notebooks docs-build ## Full local CI pass including notebooks and docs

# ── Housekeeping ──────────────────────────────────────────────────────────────

.PHONY: clean
clean: ## Remove all build artifacts and caches
	rm -rf dist/ build/ site/ htmlcov/ coverage.xml .coverage typst/output/
	find . -type d -name __pycache__ -not -path './.git/*' -prune -exec rm -rf {} +
	find . -type d -name .pytest_cache -not -path './.git/*' -prune -exec rm -rf {} +
	find . -type d -name .mypy_cache  -not -path './.git/*' -prune -exec rm -rf {} +
	find . -type d -name .ruff_cache  -not -path './.git/*' -prune -exec rm -rf {} +
	find . -type d -name .ipynb_checkpoints -not -path './.git/*' -prune -exec rm -rf {} +
