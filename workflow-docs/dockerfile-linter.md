## Workflow Name: Hadolint

#### Purpose: 

- This workflow automates the linting of Dockerfiles using Hadolint and uploads the results to GitHub in SARIF format for further analysis.

- This workflow ensures that Dockerfiles are automatically checked for best practices and potential issues, with results easily accessible within GitHub.

#### Trigger Events:

`Push`: Runs on pushes to the dev and main branches.

`Pull Request`: Runs on pull requests targeting the dev branch.

`Scheduled`: Runs every Sunday at 13:17 UTC.

#### Permissions:

`Contents: read:` Grants read-only access to the repository contents.

`Security-events: write:` Allows uploading SARIF results.

`Actions: read:` Required for private repositories to retrieve Action run status.

- Runs on: ubuntu-latest

#### Workflow Steps:

- Checkout Code

- Run Hadolint

Generates a SARIF file with the results.

- Upload Analysis Results:

Uses github/codeql-action/upload-sarif@v2 to upload the SARIF file to GitHub for security analysis and code scanning.
