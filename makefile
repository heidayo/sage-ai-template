.PHONY: help validate trace-check id-gen adopt doctor repair report

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# --- SAGE Commands ---

validate: ## Run SAGE validation (CLAUDE.md structure + template fields)
	@bash scripts/sage-validate.sh

trace-check: ## Validate traceability chain in recent commits/PRs
	@bash scripts/sage-trace-check.sh

id-gen: ## Generate next SPEC/PLAN/TASK ID (usage: make id-gen TYPE=spec)
	@bash scripts/sage-id-gen.sh $(TYPE)

adopt: ## Apply SAGE Phase A to current repository (non-destructive)
	@bash scripts/sage-adopt.sh

doctor: ## Run SAGE health check (file integrity + security scan)
	@bash scripts/sage-doctor.sh

repair: ## Repair MISSING/MISMATCH managed files
	@bash scripts/sage-repair.sh

report: ## Show SAGE system health report
	@bash scripts/sage-report.sh

# --- Development Commands (customize per project) ---

# test: ## Run tests
# 	@echo "Configure test command for your project"

# lint: ## Run linter
# 	@echo "Configure lint command for your project"

# format: ## Format code
# 	@echo "Configure format command for your project"
