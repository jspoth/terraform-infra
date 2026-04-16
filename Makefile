ENV      ?= dev
RESOURCE ?= general
DIR       = environments/$(ENV)/$(RESOURCE)

.PHONY: init plan apply destroy deploy

init:
	terraform -chdir=$(DIR) init

plan:
	terraform -chdir=$(DIR) plan

apply:
	@if [ "$(RESOURCE)" = "addons" ]; then \
		terraform -chdir=$(DIR) init && \
		terraform -chdir=$(DIR) apply \
			-target=module.karpenter.module.karpenter \
			-target=module.karpenter.helm_release.karpenter && \
		terraform -chdir=$(DIR) apply; \
	else \
		terraform -chdir=$(DIR) apply; \
	fi

destroy:
	terraform -chdir=$(DIR) destroy

# Deploy EKS then Karpenter in order
deploy:
	$(MAKE) apply RESOURCE=general
	$(MAKE) apply RESOURCE=addons
