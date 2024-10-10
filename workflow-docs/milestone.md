## Workflow Name: Milestone Workflow

#### Purpose: 

- This workflow is designed to close a specific milestone on GitHub and trigger a release workflow. It is manually triggered with a specified milestone ID.

- This workflow streamlines the process of managing milestones and automates the transition to the release process.

#### Trigger Events:

`Workflow Dispatch`: This workflow is triggered manually with a milestoneId input.

- Runs on: ubuntu-latest

#### Workflow Steps:

- Checkout Repository:

Uses actions/checkout@v2 to clone the repository.

- Set Up Environment Variables:

Sets up necessary environment variables, including the GitHub token, milestone number, and GitHub API URL.

- Close Milestone:

Uses the GitHub API to close the specified milestone.

- Trigger Release Workflow:

Triggers another workflow for releasing, passing the milestone number as a payload using the peter-evans/repository-dispatch@v1 action.
