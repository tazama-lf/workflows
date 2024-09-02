## Workflow Name: CodeQL

#### Purpose: 

- This workflow automates the process of scanning code for vulnerabilities using GitHub's CodeQL analysis.

#### Trigger Events:

`Push`: Runs on pushes to the dev and main branches.

`Pull Requests`: Runs on pull requests targeting dev and main.

`Scheduled`: Runs every Thursday at 00:34 UTC.

#### Permissions:

`actions: read`

`contents: read`

`security-events: write`

#### Workflow Steps:

- Checkout Repository: Uses actions/checkout@v4 to clone the repository.
  
- Initialize CodeQL: Prepares the CodeQL environment for the specified languages.
  
- Autobuild: Automatically builds the codebase (useful for compiled languages).
  
- Perform CodeQL Analysis: Executes the CodeQL scan and uploads results.
  
#### Language Support:
The workflow is configured to scan JavaScript code but can be extended to support other languages like Java, Python, Go, etc.

This setup ensures that your code is continuously analyzed for security vulnerabilities and quality issues.