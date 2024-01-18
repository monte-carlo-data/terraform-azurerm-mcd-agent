.PHONY: default apply test exec clean

default:
	@echo "Read the readme"

apply:
	@# Apply this example.
	terraform init && terraform apply -auto-approve

test:
	@# Test agent reachability via the health endpoint.
	@# This command expects that you have have applied this example. Use exec to do both steps.
	@curl -s $$(terraform output -raw function_url)/api/v1/test/health -H \
  		"x-functions-key: $$(az functionapp keys list -g $$(terraform output -raw resource_group) \
  		-n $$(terraform output -raw function_name) | jq -r '.functionKeys.default')" | jq

exec: apply sleep-30 test  # Sleep to wait on initial propagation. Subsequent usage should require no delay.

clean:
	@# Delete this example.
	@# WARNING -- This command will delete resources and local state files. This is unrecoverable.
	terraform destroy -auto-approve && rm -rf .terraform* terraform.tfstate*

sleep-%:
	sleep $(@:sleep-%=%)
