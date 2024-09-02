## Workflow Name: GPG Verify

#### Purpose: 

- This workflow automatically verifies the GPG signatures of commits in a pull request, ensuring that all commits are signed and verified as part of the code review process.

- This workflow helps enforce the use of GPG-signed commits, adding an extra layer of security to the contribution process.

- If any commit fails the GPG verification, the workflow fails, ensuring only verified commits are merged.

#### Trigger Events:

`Pull Request`: The workflow triggers whenever a pull request is opened or updated.

- Runs on: ubuntu-latest

#### Workflow Steps:

- Checkout Repository:

- Set Up Environment Variables:

Captures the head and base references of the pull request and sets up necessary environment variables.

- Check GPG Verification Status:

Retrieves the list of commits in the pull request. For each commit, it checks the GPG verification status using GitHub's API.
