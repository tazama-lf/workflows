## GitHub Action Workflow Documentation: Sync Workflows

#### Purpose

- This GitHub Action workflow automates the process of synchronizing workflow files across multiple repositories whenever a pull request (PR) is merged into the dev branch.

- This workflow ensures that all specified repositories maintain consistent CI/CD workflows by automatically syncing changes from a central repository when updates are made.

#### Trigger Event

`pull_request`

`types: [closed]` - This workflow triggers when a pull request is closed.

`branches: [ "dev" ]` - It specifically listens to pull requests merged into the dev branch.


#### Jobs

- Job: sync

`Condition`:

if: github.event.pull_request.merged == true - This job only runs if the pull request was successfully merged.

- Runs on: ubuntu-latest - The job uses the latest Ubuntu runner.

#### Workflow Steps

- Checkout Central Workflows Repo

- Set up Git

- Install GitHub CLI

- Get PR author details

- Sync Workflows to Other Repos

- Cleanup: Temporary files used for GitHub CLI authentication are removed after the operation.
