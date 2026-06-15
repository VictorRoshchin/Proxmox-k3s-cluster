TERRAFORM ?= docker compose run --rm terraform
ANSIBLE_PLAYBOOK ?= ansible-playbook
ANSIBLE_INVENTORY ?= ansible/inventories/generated/hosts.yml
ANSIBLE_PLAYBOOK_FILE ?= ansible/playbooks/site.yml
TERRAFORM_PARALLELISM ?= 1

.PHONY: init fmt validate plan apply ansible deploy output state-list destroy clean-generated

init:
	$(TERRAFORM) init

fmt:
	$(TERRAFORM) fmt -recursive

validate:
	$(TERRAFORM) validate

plan:
	$(TERRAFORM) plan

apply:
	$(TERRAFORM) apply -parallelism=$(TERRAFORM_PARALLELISM)

ansible:
	test -f $(ANSIBLE_INVENTORY)
	cd ansible && $(ANSIBLE_PLAYBOOK) -i inventories/generated/hosts.yml playbooks/site.yml

deploy: init apply ansible

output:
	$(TERRAFORM) output

state-list:
	$(TERRAFORM) state list

destroy:
	$(TERRAFORM) destroy -parallelism=$(TERRAFORM_PARALLELISM)

clean-generated:
	rm -f $(ANSIBLE_INVENTORY)
	rm -f ansible/artifacts/k3s.yaml
