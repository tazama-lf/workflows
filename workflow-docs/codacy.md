## Workflow Name: Codacy Security Scan

#### Purpose: 

- This workflow performs security scans on the codebase using Codacy and uploads the results in SARIF format to GitHub.

#### Trigger Events:

`Push`: Runs on pushes to the dev and main branches.

`Pull Requests`: Runs on pull requests targeting dev and main.

`Scheduled`: Runs every Thursday at 00:17 UTC.

#### Permissions:

`contents: read`: Allows reading repository contents.

`security-events`: write: Allows uploading SARIF results.

`actions: read`: Required for private repositories to retrieve Action run status.

- Runs on: ubuntu-latest

#### Workflow Steps:

- Checkout Code: Uses actions/checkout@v4 to clone the repository.
  
- Run Codacy Analysis CLI: Executes Codacy's CLI to scan the codebase, generating a SARIF file.
  
- Upload SARIF Results: Uploads the SARIF file to GitHub using github/codeql-action/upload-sarif@v3.
  
- This workflow ensures that security issues in the codebase are identified and reported efficiently.
