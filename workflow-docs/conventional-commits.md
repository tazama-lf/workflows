## Workflow Name: PR Conventional Commit Validation

#### Purpose: 

- This workflow automatically validates the title of a pull request (PR) to ensure it follows conventional commit guidelines. It also applies corresponding GitHub labels based on the commit type.

- Uses the ytanikin/PRConventionalCommits@1.1.0 action.

- Validates the PR title against a set of predefined conventional commit types (e.g., feat, fix, docs).

- Maps these types to corresponding GitHub labels and applies them to the PR.

- Utilizes a GitHub token for authentication and label management.

- This workflow helps enforce commit message conventions and improve PR management by automatically labeling PRs based on their titles.

#### Trigger Events:

`Pull Request Events`: The workflow is triggered when a pull request is opened, synchronized, reopened, or edited.

#### Workflow Steps:

- Checkout Code: Uses actions/checkout@v4 to check out the repository.

- PR Conventional Commit Validation:
