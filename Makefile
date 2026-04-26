ENV      ?= dev
RESOURCE ?= general
DIR       = environments/$(ENV)/$(RESOURCE)

LAYERS = general permissions addons messaging datastores

.PHONY: init plan apply destroy deploy check check-all dns

init:
	terraform -chdir=$(DIR) init

plan:
	terraform -chdir=$(DIR) plan

check:
	terraform -chdir=$(DIR) init && terraform -chdir=$(DIR) plan

check-all:
	@for layer in $(LAYERS); do \
		echo "──── $$layer ────"; \
		$(MAKE) check RESOURCE=$$layer ENV=$(ENV); \
	done

apply:
	@if [ "$(RESOURCE)" = "addons" ]; then \
		terraform -chdir=$(DIR) init && \
		terraform -chdir=$(DIR) apply \
			-target=module.karpenter.module.karpenter \
			-target=module.karpenter.helm_release.karpenter && \
		terraform -chdir=$(DIR) apply; \
	else \
		terraform -chdir=$(DIR) init && terraform -chdir=$(DIR) apply; \
	fi

destroy:
	terraform -chdir=$(DIR) destroy

# Deploy all layers in dependency order:
#   general (VPC + EKS) → permissions (IRSA + ESO role) → addons (Karpenter + ESO + Reloader) → messaging (SQS)
#   datastores (DynamoDB) excluded — prevent_destroy, managed separately
#   permissions before addons because ESO Helm chart needs the ESO IRSA role to exist
#   dns excluded — must run after kubectl apply (ALB must exist before dns layer can resolve it)
deploy:
	$(MAKE) apply RESOURCE=general
	$(MAKE) apply RESOURCE=permissions
	$(MAKE) apply RESOURCE=addons
	$(MAKE) apply RESOURCE=messaging

# Sync Route 53 to the current ALB provisioned by the LBC.
# Run after kubectl apply — ALB must exist before this layer resolves.
dns:
	$(MAKE) apply RESOURCE=dns
