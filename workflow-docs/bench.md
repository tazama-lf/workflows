## Workflow Name: Benchmark CI

#### Purpose:

- This workflow automates the process of updating and pushing benchmark data to the main branch of a repository.

#### Environment Variables:

`GITHUB_TOKEN`: GitHub token for authentication.

`REPO_NAME`: The repository name where benchmark data is stored.

`PROCCESSOR_REPO_NAME`: The name of the repository triggering the workflow.

#### Trigger Events:

`On`: push to the main branch.

- Runs on: ubuntu-latest

#### Workflow Steps:

- Clone repo: Clone the benchmark repository using the GitHub token.
  
- Switch to temp branch: Switch to a temporary branch, stash changes, and prepare the data file for update.

- Write data: Append new benchmark data from the triggering repository to the CSV file and commit the changes.
  
- Push data: Push the updated data back to the main branch of the benchmark repository.