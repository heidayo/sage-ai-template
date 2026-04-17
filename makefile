.PHONY: help validate trace-check id-gen adopt doctor repair report check-installer-sync

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

check-installer-sync: ## Compare local install.sh sha256 with published Gist (SPEC-0008 TASK-0081)
	@URL=$$(grep -E '^\s*installer_url:' .sage/config.yaml | head -1 | sed -E 's/^[^"]*"([^"]*)".*/\1/'); \
	if [ -z "$$URL" ]; then echo "SKIPPED: installer_url not set"; exit 0; fi; \
	if ! command -v curl >/dev/null 2>&1; then echo "SKIPPED: curl not available"; exit 0; fi; \
	LOCAL=$$(shasum -a 256 install.sh 2>/dev/null | awk '{print $$1}'); \
	REMOTE=$$(curl -fsSL --max-time 10 "$$URL" 2>/dev/null | shasum -a 256 | awk '{print $$1}'); \
	if [ -z "$$REMOTE" ]; then echo "SKIPPED: Gist not reachable"; exit 0; fi; \
	if [ "$$LOCAL" = "$$REMOTE" ]; then echo "OK: install.sh matches Gist sha256=$$LOCAL"; else echo "MISMATCH: local=$$LOCAL remote=$$REMOTE"; exit 1; fi

# --- Development Commands (customize per project) ---

# test: ## Run tests
# 	@echo "Configure test command for your project"

# lint: ## Run linter
# 	@echo "Configure lint command for your project"

# format: ## Format code
# 	@echo "Configure format command for your project"
