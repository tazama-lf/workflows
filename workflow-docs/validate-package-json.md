## Workflow Name: PR Conventional Commit Validation

#### Purpose: 

- This GitHub Action workflow is designed to validate the `package.json` file when a PR is submitted to check that it is as defined in the contribution guide

#### Trigger Events

Trigger: The workflow is triggered on push and pull_request events to the main branch.

#### Jobs

Checkout Repository: The repository is checked out using the actions/checkout@v3 action.

Validate package.json:

- The script first checks if package.json exists.

- It then uses jq to extract the name, author.email, and author.url fields from package.json.

- The script compares these fields against the required values (Tazama, engineering@tazama.org, and tazama.org).

- If any of the fields do not match, the script exits with an error message.

- Output Validation Result: If the validation is successful, a success message is printed.

