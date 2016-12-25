# Terraform Modules

Custom Terraform modules primarily intended to be included in a project derived from [prepd-project]
(https://github.com/rjayroach/prepd-project/) to provide a set of infrastructure blueprints.

## Using

Add these modules as a submodule in the 'modules' directory of an existing repo:

```bash
cd terraform
git submodule add git@github.com:rjayroach/terraform-modules modules
```

Updating the submodule to the latest code on master:

```bash
git submodule update --remote --merge
```

## Updating Code

Code changed in the submodule can be [committed and pushed]
(https://chrisjean.com/git-submodules-adding-using-removing-and-updating) like any other repo.
