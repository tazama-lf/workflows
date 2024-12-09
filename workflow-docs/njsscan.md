## Workflow Name: njsscan sarif

#### Purpose:

- This GitHub workflow is designed to run the njsscan code scanning tool and upload the results as a SARIF (Static Analysis Results Interchange Format) report to GitHub. Here's a detailed breakdown of the workflow:

- This workflow ensures that every push and pull request to the dev and main branches, as well as a weekly scheduled run, triggers a security scan using njsscan. The results are then uploaded to GitHub in SARIF format, allowing the repository maintainers to review and address potential security issues.

#### Trigger Events

`push`:

`branches: [ "dev", "main" ]`: The workflow will trigger whenever there is a push to the dev or main branches.

`pull_request`:

`branches: [ "dev", "main" ]`: The workflow will also trigger when a pull request is made targeting the dev or main branches.

`schedule`:

`cron: '17 17 * * 1'`: The workflow is scheduled to run automatically every Monday at 17:17 UTC.


#### permissions:

`contents`: read: Grants read access to the repository contents for the entire workflow.

#### Workflow Steps

- Checkout the code

- njsscan
